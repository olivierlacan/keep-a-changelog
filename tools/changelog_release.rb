#!/usr/bin/env ruby
# frozen_string_literal: true

# Keeps GitHub Releases in sync with CHANGELOG.md. The changelog is the source of
# truth; every release is derived from it.
#
# This file is both a library (require it and the classes below are testable in
# isolation — see test/changelog_release_test.rb) and a command-line tool:
#
#   ruby tools/changelog_release.rb create   # default
#       Create a release for the latest dated version if one doesn't exist yet.
#       Idempotent: does nothing if the release is already there.
#
#   ruby tools/changelog_release.rb sync
#       Same create-if-missing for the latest version, then reconcile the body of
#       *every* existing release against its changelog entry, updating any that
#       have drifted. This is how a translation added to an already-released
#       version (same minor, or a patch) gets pushed up to its published release.
#
# All GitHub/git access goes through GitHubCli, which is injected into Runner so
# the orchestration can be tested against a fake without touching the network.
# Reads CHANGELOG.md from the repository root; uses GITHUB_SHA for the tag commit.

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

  # Orchestrates create/sync against an injected +github+ adapter.
  class Runner
    def initialize(entries, github:, logger: $stderr)
      @entries = entries
      @github = github
      @logger = logger
    end

    # Create a release for the latest version if it doesn't exist yet. Returns
    # true if it created one, false if the release was already there.
    def create_latest(sha:)
      entry = @entries.first
      if @github.release_exists?(entry.tag)
        log "#{entry.tag} already exists — nothing to create."
        return false
      end

      log "Creating release #{entry.tag} (version #{entry.version}, dated #{entry.date})…"
      @github.create_tag(entry.tag, message: entry.version, date: entry.date, sha: sha) unless @github.tag_exists?(entry.tag)
      @github.create_release(tag: entry.tag, title: entry.title, notes: entry.notes)
      true
    end

    # Update the body of every existing release whose notes have drifted from the
    # changelog. Releases that don't exist yet are skipped (create_latest owns the
    # newest one); releases that already match are left untouched. Returns the
    # tags it updated.
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

    private

    def log(message)
      @logger.puts(message)
    end
  end
end

# --- Command-line entry point ----------------------------------------------

if $PROGRAM_NAME == __FILE__
  mode = ARGV.fetch(0, "create")
  root = File.expand_path("..", __dir__)
  entries = ChangelogRelease.parse(File.read(File.join(root, "CHANGELOG.md")))
  abort "No dated version heading (## [x.y.z] - YYYY-MM-DD) found in CHANGELOG.md" if entries.empty?

  runner = ChangelogRelease::Runner.new(entries, github: ChangelogRelease::GitHubCli.new)

  case mode
  when "create"
    runner.create_latest(sha: ENV.fetch("GITHUB_SHA"))
  when "sync"
    runner.create_latest(sha: ENV.fetch("GITHUB_SHA"))
    runner.sync_all
  else
    abort %(Unknown mode #{mode.inspect}. Use "create" or "sync".)
  end
end
