#!/usr/bin/env ruby
# frozen_string_literal: true

# Keeps GitHub Releases in sync with CHANGELOG.md. The changelog is the source of
# truth; every release is derived from it.
#
# This file is both a library (require it and the classes below are testable in
# isolation — see test/changelog_release_test.rb) and a command-line tool:
#
#   ruby tools/changelog_release.rb create [--dry-run]
#       Create a release for every dated version that doesn't have one yet.
#       Idempotent: skips versions whose release already exists.
#
#   ruby tools/changelog_release.rb sync [--dry-run]
#       Create every missing release (as above), then reconcile the body of
#       *every* existing release against its changelog entry, updating any that
#       have drifted. This is how a translation added to an already-released
#       version (same minor, or a patch) gets pushed up to its published release.
#
#   --dry-run
#       Don't touch anything. Print the plan — which releases would be created
#       and a diff of any that would be updated — and report whether there are
#       changes (via GITHUB_OUTPUT) so a workflow can gate an approval step on it.
#
# All GitHub/git access goes through GitHubCli, which is injected into Runner so
# the orchestration can be tested against a fake without touching the network.

require "open3"
require "tempfile"

module ChangelogRelease
  # A single dated release parsed from CHANGELOG.md.
  Entry = Struct.new(:version, :tag, :date, :yanked, :notes, keyword_init: true) do
    # The title GitHub should show for the release. Mirrors the "[YANKED]" marker
    # the changelog uses on a heading.
    def title
      yanked ? "#{version} [YANKED]" : version
    end
  end

  # One line of the dry-run plan. +action+ is :create, :update, or :unchanged;
  # +details+ holds the new notes (:create) or a unified diff (:update).
  PlanItem = Struct.new(:tag, :date, :action, :details, keyword_init: true)

  # Human-readable labels for each plan action, used in the summary table.
  ACTION_LABELS = {
    create: "🆕 create",
    update: "✏️ update",
    unchanged: "✓ unchanged"
  }.freeze

  # A dated version heading, e.g. "## [1.1.0] - 2019-02-15" — skips
  # "## [Unreleased]" and tolerates a trailing "[YANKED]" marker.
  HEADING = /^\#\#\s*\[(?<version>\d+\.\d+\.\d+)\]\s*-\s*(?<date>\d{4}-\d{2}-\d{2})(?<rest>.*)$/

  # Parse every dated version out of changelog text, newest first (the order the
  # changelog is written in). Returns an array of Entry; empty if none match.
  def self.parse(text)
    lines = text.lines
    lines.each_index.filter_map do |index|
      match = lines[index].match(HEADING)
      next unless match

      Entry.new(
        version: match[:version],
        tag: "v#{match[:version]}",
        date: match[:date],
        yanked: match[:rest].include?("[YANKED]"),
        notes: body_after(lines, index)
      )
    end
  end

  # The section body following the heading at +index+: everything up to the next
  # version heading or the reference-link definition block at the bottom of the
  # file, with surrounding blank lines trimmed.
  def self.body_after(lines, index)
    body = []
    lines[(index + 1)..].each do |line|
      break if line.match?(/^\#\#\s/) # next section heading
      break if line.match?(/^\[[^\]]+\]:\s/) # link reference definitions

      body << line
    end
    body.join.strip
  end

  # Normalize a release body for comparison so cosmetic-only differences don't
  # read as drift: unify line endings, strip trailing whitespace per line, and
  # drop leading/trailing blank lines. Internal blank lines are preserved.
  def self.normalize(body)
    lines = body.to_s.tr("\r", "").split("\n", -1).map(&:rstrip)
    lines.shift while lines.first&.empty?
    lines.pop while lines.last&.empty?
    lines.join("\n")
  end

  # Line-level diff between two bodies (after normalizing both), via a longest
  # common subsequence. Returns [[:equal|:delete|:insert, line], ...].
  def self.diff_ops(old_text, new_text)
    old_lines = normalize(old_text).split("\n")
    new_lines = normalize(new_text).split("\n")
    rows = old_lines.length
    cols = new_lines.length

    lcs = Array.new(rows + 1) { Array.new(cols + 1, 0) }
    (rows - 1).downto(0) do |i|
      (cols - 1).downto(0) do |j|
        lcs[i][j] = if old_lines[i] == new_lines[j]
          lcs[i + 1][j + 1] + 1
        else
          [lcs[i + 1][j], lcs[i][j + 1]].max
        end
      end
    end

    ops = []
    i = 0
    j = 0
    while i < rows && j < cols
      if old_lines[i] == new_lines[j]
        ops << [:equal, old_lines[i]]
        i += 1
        j += 1
      elsif lcs[i + 1][j] >= lcs[i][j + 1]
        ops << [:delete, old_lines[i]]
        i += 1
      else
        ops << [:insert, new_lines[j]]
        j += 1
      end
    end
    old_lines[i..].each { |line| ops << [:delete, line] }
    new_lines[j..].each { |line| ops << [:insert, line] }
    ops
  end

  # A `diff -u`-style string (lines prefixed with " ", "-", "+"), with long runs
  # of unchanged lines collapsed to a "@@ N unchanged line(s) @@" marker so the
  # plan stays readable when a release body has drifted a lot.
  def self.unified_diff(old_text, new_text, context: 3)
    collapse(diff_ops(old_text, new_text), context).map do |type, text|
      case type
      when :equal then " #{text}"
      when :delete then "-#{text}"
      when :insert then "+#{text}"
      when :skip then "@@ #{text} unchanged line(s) @@"
      end
    end.join("\n")
  end

  # Trim runs of unchanged lines down to +context+ lines on each side of a change.
  def self.collapse(ops, context)
    result = []
    index = 0
    while index < ops.length
      unless ops[index].first == :equal
        result << ops[index]
        index += 1
        next
      end

      run = 1
      run += 1 while ops[index + run]&.first == :equal
      keep_before = index.zero? ? 0 : context
      keep_after = (index + run >= ops.length) ? 0 : context

      if run > keep_before + keep_after
        ops[index, keep_before].each { |op| result << op }
        result << [:skip, run - keep_before - keep_after]
        ops[index + run - keep_after, keep_after].each { |op| result << op }
      else
        ops[index, run].each { |op| result << op }
      end
      index += run
    end
    result
  end

  # True if the plan would create or update at least one release.
  def self.changes?(items)
    items.any? { |item| %i[create update].include?(item.action) }
  end

  # Render a plan as Markdown for a GitHub Actions job summary (and console).
  def self.format_plan(items, sync:)
    lines = ["## Release plan (#{sync ? "create + sync" : "create"})", ""]
    lines << "| Tag | Date | Action |"
    lines << "|-----|------|--------|"
    items.each { |item| lines << "| `#{item.tag}` | #{item.date} | #{ACTION_LABELS.fetch(item.action)} |" }

    actionable = items.select { |item| %i[create update].include?(item.action) }
    if actionable.empty?
      lines << ""
      lines << "_Nothing to create or update — every release already matches the changelog._"
    else
      actionable.each do |item|
        if item.action == :create
          heading = "### `#{item.tag}` — new release"
          fence = "```"
        else
          heading = "### `#{item.tag}` — update"
          fence = "```diff"
        end
        lines << "" << heading << "" << fence << item.details << "```"
      end
    end

    "#{lines.join("\n")}\n"
  end

  # Real GitHub/git access via the `gh` and `git` CLIs. Each method maps to one
  # observable action so a fake can stand in for it in tests.
  class GitHubCli
    def release_exists?(tag)
      system("gh", "release", "view", tag, out: File::NULL, err: File::NULL) || false
    end

    def release_body(tag)
      out, status = Open3.capture2("gh", "release", "view", tag, "--json", "body", "-q", ".body")
      status.success? ? out : ""
    end

    def tag_exists?(tag)
      system("git", "rev-parse", "-q", "--verify", "refs/tags/#{tag}", out: File::NULL, err: File::NULL) || false
    end

    # Create an annotated tag at +sha+, dated to the changelog entry so the tag
    # carries the right date even though GitHub stamps the release with the
    # publish time. Pushes it so `gh release create --verify-tag` can find it.
    def create_tag(tag, message:, date:, sha:)
      stamp = "#{date}T12:00:00Z"
      bot = "github-actions[bot]"
      email = "github-actions[bot]@users.noreply.github.com"
      env = {
        "GIT_AUTHOR_DATE" => stamp, "GIT_COMMITTER_DATE" => stamp,
        "GIT_AUTHOR_NAME" => bot, "GIT_COMMITTER_NAME" => bot,
        "GIT_AUTHOR_EMAIL" => email, "GIT_COMMITTER_EMAIL" => email
      }
      run!(["git", "tag", "-a", tag, "-m", message, sha], env: env)
      run!(["git", "push", "origin", "refs/tags/#{tag}"])
    end

    def create_release(tag:, title:, notes:)
      with_notes_file(notes) do |path|
        run!(["gh", "release", "create", tag, "--title", title, "--notes-file", path, "--verify-tag"])
      end
    end

    def update_release_notes(tag:, notes:)
      with_notes_file(notes) do |path|
        run!(["gh", "release", "edit", tag, "--notes-file", path])
      end
    end

    private

    def run!(command, env: {})
      raise "command failed: #{command.join(" ")}" unless system(env, *command)
    end

    def with_notes_file(notes)
      Tempfile.create("release-notes") do |file|
        file.write(notes.end_with?("\n") ? notes : "#{notes}\n")
        file.flush
        yield file.path
      end
    end
  end

  # Orchestrates create/sync/plan against an injected +github+ adapter.
  class Runner
    def initialize(entries, github:, logger: $stderr)
      @entries = entries
      @github = github
      @logger = logger
    end

    # Create a release for every dated version that doesn't have one yet, oldest
    # first so the timeline is built in order. Existing releases are left alone.
    # Tags are created (dated to the changelog entry) only when missing. Returns
    # the tags it created.
    def create_missing(sha:)
      @entries.reverse_each.each_with_object([]) do |entry, created|
        if @github.release_exists?(entry.tag)
          log "#{entry.tag} already exists — skipping."
          next
        end

        log "Creating release #{entry.tag} (version #{entry.version}, dated #{entry.date})…"
        @github.create_tag(entry.tag, message: entry.version, date: entry.date, sha: sha) unless @github.tag_exists?(entry.tag)
        @github.create_release(tag: entry.tag, title: entry.title, notes: entry.notes)
        created << entry.tag
      end
    end

    # Update the body of every existing release whose notes have drifted from the
    # changelog. Releases that don't exist yet are skipped (create_missing makes
    # those); releases that already match are left untouched. Returns the tags it
    # updated.
    def sync_all
      @entries.each_with_object([]) do |entry, updated|
        unless @github.release_exists?(entry.tag)
          log "#{entry.tag} — no release yet, skipping."
          next
        end

        if ChangelogRelease.normalize(@github.release_body(entry.tag)) == ChangelogRelease.normalize(entry.notes)
          log "#{entry.tag} — already matches."
        else
          @github.update_release_notes(tag: entry.tag, notes: entry.notes)
          log "#{entry.tag} — body drifted, updated from changelog."
          updated << entry.tag
        end
      end
    end

    # Compute, without making any changes, what create/sync would do. Every
    # missing release is planned as a create. +mode+ :sync additionally reconciles
    # existing releases (so they show as :update or :unchanged); :create leaves
    # existing releases untouched (always :unchanged). Returns an array of PlanItem.
    def plan(mode:)
      reconcile = mode == :sync
      @entries.map { |entry| plan_for(entry, reconcile: reconcile) }
    end

    private

    def plan_for(entry, reconcile:)
      unless @github.release_exists?(entry.tag)
        return PlanItem.new(tag: entry.tag, date: entry.date, action: :create, details: entry.notes)
      end

      return PlanItem.new(tag: entry.tag, date: entry.date, action: :unchanged) unless reconcile

      current = @github.release_body(entry.tag)
      if ChangelogRelease.normalize(current) == ChangelogRelease.normalize(entry.notes)
        PlanItem.new(tag: entry.tag, date: entry.date, action: :unchanged)
      else
        PlanItem.new(tag: entry.tag, date: entry.date, action: :update,
          details: ChangelogRelease.unified_diff(current, entry.notes))
      end
    end

    def log(message)
      @logger.puts(message)
    end
  end
end

# --- Command-line entry point ----------------------------------------------

if $PROGRAM_NAME == __FILE__
  args = ARGV.dup
  dry_run = !args.delete("--dry-run").nil?
  action = args.fetch(0, "create")
  mode = {"create" => :create, "sync" => :sync}[action]
  abort %(Unknown action #{action.inspect}. Use "create" or "sync".) if mode.nil?

  root = File.expand_path("..", __dir__)
  entries = ChangelogRelease.parse(File.read(File.join(root, "CHANGELOG.md")))
  abort "No dated version heading (## [x.y.z] - YYYY-MM-DD) found in CHANGELOG.md" if entries.empty?

  runner = ChangelogRelease::Runner.new(entries, github: ChangelogRelease::GitHubCli.new)

  if dry_run
    items = runner.plan(mode: mode)
    report = ChangelogRelease.format_plan(items, sync: mode == :sync)
    warn report
    File.write(ENV["GITHUB_STEP_SUMMARY"], report, mode: "a") if ENV["GITHUB_STEP_SUMMARY"]
    if (output = ENV["GITHUB_OUTPUT"])
      File.open(output, "a") { |file| file.puts "changes=#{ChangelogRelease.changes?(items)}" }
    end
  else
    runner.create_missing(sha: ENV.fetch("GITHUB_SHA"))
    runner.sync_all if mode == :sync
  end
end
