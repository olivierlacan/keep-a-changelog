#!/usr/bin/env ruby
# frozen_string_literal: true

# Reads released versions out of CHANGELOG.md so the release workflow can keep
# GitHub Releases in sync with it. The changelog is the source of truth; every
# release is derived from it.
#
# Default mode (create path):
#   Emits `version`, `tag`, `date`, and `yanked` for the *latest* dated version
#   to GITHUB_OUTPUT (when set), and writes that section body to
#   RELEASE_NOTES_FILE (default: release_notes.md).
#
# Sync mode (set SYNC_RELEASE_NOTES to a truthy value):
#   Parses *every* dated version, writes each one's notes to
#   <RELEASE_NOTES_DIR>/<tag>.md (default dir: release_notes), and writes a JSON
#   manifest to RELEASE_MANIFEST (default: release_manifest.json) so the workflow
#   can reconcile each existing release's body against the changelog. This is how
#   a translation added to an already-released version (same minor, or a patch)
#   gets pushed up to its published release.

require "json"

root = File.expand_path("..", __dir__)
changelog = File.read(File.join(root, "CHANGELOG.md"))
lines = changelog.lines

# A dated version heading, skipping "## [Unreleased]". Handles an optional
# "[YANKED]" marker, e.g. "## [0.0.5] - 2014-12-13 [YANKED]".
heading = /^\#\#\s*\[(?<version>\d+\.\d+\.\d+)\]\s*-\s*(?<date>\d{4}-\d{2}-\d{2})(?<rest>.*)$/

# Extract every dated version as a structured entry, in file order (newest
# first, the way the changelog is written).
entries = []
lines.each_with_index do |line, index|
  match = line.match(heading)
  next unless match

  # Body: everything after the heading until the next version heading or the
  # reference-link definition block at the bottom of the file.
  body = []
  lines[(index + 1)..].each do |body_line|
    break if body_line.match?(/^\#\#\s/)        # next section heading
    break if body_line.match?(/^\[[^\]]+\]:\s/) # link reference definitions
    body << body_line
  end

  version = match[:version]
  entries << {
    version: version,
    tag: "v#{version}",
    date: match[:date],
    yanked: match[:rest].include?("[YANKED]"),
    notes: body.join.strip,
  }
end

abort "No dated version heading (## [x.y.z] - YYYY-MM-DD) found in CHANGELOG.md" if entries.empty?

# --- Default (create path): the latest version ------------------------------

latest = entries.first

if (out = ENV["GITHUB_OUTPUT"])
  File.open(out, "a") do |f|
    f.puts "version=#{latest[:version]}"
    f.puts "tag=#{latest[:tag]}"
    f.puts "date=#{latest[:date]}"
    f.puts "yanked=#{latest[:yanked]}"
  end
end

File.write(ENV.fetch("RELEASE_NOTES_FILE", "release_notes.md"), "#{latest[:notes]}\n")

warn "Latest changelog version: #{latest[:version]} (#{latest[:tag]}), " \
     "dated #{latest[:date]}#{latest[:yanked] ? ' [YANKED]' : ''}"

# --- Sync mode: every version, with a manifest to reconcile against ---------

def truthy?(value)
  return false if value.nil?

  %w[1 true yes on].include?(value.strip.downcase)
end

exit 0 unless truthy?(ENV["SYNC_RELEASE_NOTES"])

notes_dir = ENV.fetch("RELEASE_NOTES_DIR", "release_notes")
require "fileutils"
FileUtils.mkdir_p(notes_dir)

manifest = entries.map do |entry|
  notes_file = File.join(notes_dir, "#{entry[:tag]}.md")
  File.write(notes_file, "#{entry[:notes]}\n")
  {
    tag: entry[:tag],
    version: entry[:version],
    date: entry[:date],
    yanked: entry[:yanked],
    title: entry[:yanked] ? "#{entry[:version]} [YANKED]" : entry[:version],
    notes_file: notes_file,
  }
end

File.write(ENV.fetch("RELEASE_MANIFEST", "release_manifest.json"), "#{JSON.pretty_generate(manifest)}\n")

if (out = ENV["GITHUB_OUTPUT"])
  File.open(out, "a") { |f| f.puts "sync=true" }
end

warn "Sync mode: wrote notes for #{entries.length} version(s) to #{notes_dir}/ and a manifest."
