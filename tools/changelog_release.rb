#!/usr/bin/env ruby
# frozen_string_literal: true

# Extracts the latest released version from CHANGELOG.md so the release workflow
# can create a matching GitHub release when one is missing. The changelog is the
# source of truth; the release is derived from it.
#
# Emits `version`, `tag`, `date`, and `yanked` to GITHUB_OUTPUT (when set), and
# writes the section body to RELEASE_NOTES_FILE (default: release_notes.md).

root = File.expand_path("..", __dir__)
changelog = File.read(File.join(root, "CHANGELOG.md"))
lines = changelog.lines

# First dated version heading, skipping "## [Unreleased]". Handles an optional
# "[YANKED]" marker, e.g. "## [0.0.5] - 2014-12-13 [YANKED]".
heading = /^\#\#\s*\[(?<version>\d+\.\d+\.\d+)\]\s*-\s*(?<date>\d{4}-\d{2}-\d{2})(?<rest>.*)$/
start = lines.index { |line| line.match?(heading) }
abort "No dated version heading (## [x.y.z] - YYYY-MM-DD) found in CHANGELOG.md" if start.nil?

match = lines[start].match(heading)
version = match[:version]
date = match[:date]
yanked = match[:rest].include?("[YANKED]")

# Body: everything after the heading until the next version heading or the
# reference-link definition block at the bottom of the file.
body = []
lines[(start + 1)..].each do |line|
  break if line.match?(/^\#\#\s/)        # next section heading
  break if line.match?(/^\[[^\]]+\]:\s/) # link reference definitions
  body << line
end
notes = body.join.strip

tag = "v#{version}"

if (out = ENV["GITHUB_OUTPUT"])
  File.open(out, "a") do |f|
    f.puts "version=#{version}"
    f.puts "tag=#{tag}"
    f.puts "date=#{date}"
    f.puts "yanked=#{yanked}"
  end
end

File.write(ENV.fetch("RELEASE_NOTES_FILE", "release_notes.md"), "#{notes}\n")

warn "Latest changelog version: #{version} (#{tag}), dated #{date}#{yanked ? ' [YANKED]' : ''}"
