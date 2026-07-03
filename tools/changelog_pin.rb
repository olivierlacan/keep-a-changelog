# frozen_string_literal: true

require "rubygems" # Gem::Version

# Derives a version-pinned view of the project's own CHANGELOG.md — the hero
# "Example changelog" shown on each spec page — so the example always follows
# the conventions of the spec version being read.
#
# The live CHANGELOG.md tracks the *newest* spec it documents. A page for an
# older spec (say /en/1.1.0/ once the changelog records 2.0.0, or /en/2.0.0/
# after 2.1.0 is released — see the report in issue #720) should show the
# changelog as it stood at that track's last release, not one written to newer
# conventions. Rather than snapshotting files or maintaining per-minor tracking
# branches (the production deploy builds from a single shallow checkout, so
# other branches and tags aren't even available at build time), the pinned view
# is derived from the one live CHANGELOG.md at render time:
#
#   - entries newer than the page's major.minor track are dropped, along with
#     their version link definitions
#   - the Unreleased section keeps its heading (it's part of the format being
#     taught) but is emptied — its contents describe work newer than the track
#   - the [unreleased] compare link is rewritten to diff from the track's last
#     release, and the "based on Keep a Changelog" spec URL in the preamble is
#     rewritten to the page's version
#
# CHANGELOG.md stays the single source of truth (the same philosophy as
# tools/changelog_release.rb), there is no release-checklist step to forget,
# and later copy edits to old entries still reach the pinned views.
#
# Pure and framework-free so it can be unit-tested without booting Middleman.
# See test/changelog_pin_test.rb.
module ChangelogPin
  module_function

  # A version heading, dated or not, e.g. "## [1.1.0] - 2019-02-15".
  VERSION_HEADING = /^\#\#\s*\[(\d+\.\d+\.\d+)\]/
  UNRELEASED_HEADING = /^\#\#\s*\[unreleased\]/i

  # Reference-link definitions at the bottom of the file.
  VERSION_LINK_DEF = /^\[(\d+\.\d+\.\d+)\]:\s/
  UNRELEASED_LINK_DEF = /^\[unreleased\]:\s/i
  LINK_DEF = /^\[[^\]]+\]:\s/

  # Should +page_version+'s page show a pinned view instead of the live
  # changelog? Only when the changelog already documents a release on a newer
  # major.minor track than the page's — the moment a 2.0.0 entry lands, the
  # 1.1.0 page pins to the 1.1.x era, regardless of which version the site
  # currently publishes as its default. The page for the newest documented
  # track (and any still-undocumented draft) shows the live file, Unreleased
  # section and all.
  def pinned?(text, page_version)
    newest = text.scan(VERSION_HEADING).flatten.max_by { |v| Gem::Version.new(v) }
    return false unless newest
    track(newest) > track(page_version)
  end

  # A version's major.minor track, as a comparable Gem::Version.
  def track(version)
    Gem::Version.new(version.split(".").first(2).join("."))
  end

  # The newest release recorded in +text+ on the page's major.minor track —
  # patch releases ship translations and site fixes without changing the spec,
  # so the 2.0.0 page pins to the last 2.0.x, not to 2.0.0 itself. Returns nil
  # if the changelog has no entry on that track.
  def track_release(text, page_version)
    major, minor, = page_version.split(".")
    prefix = "#{major}.#{minor}."
    text.scan(VERSION_HEADING).flatten
      .select { |version| version.start_with?(prefix) }
      .max_by { |version| Gem::Version.new(version) }
  end

  # The changelog as it stood at the last release on +page_version+'s track.
  # Returns +text+ unchanged when the track has no recorded release to pin to.
  def pin(text, page_version)
    cutoff_string = track_release(text, page_version)
    return text unless cutoff_string

    cutoff = Gem::Version.new(cutoff_string)
    out = []
    dropping = false

    text.each_line do |raw|
      line = raw.chomp

      # The link-definition block ends the sections, so it is handled first —
      # these lines are kept or dropped on their own terms, never as part of a
      # dropped section body.
      if (match = line.match(VERSION_LINK_DEF))
        out << line unless Gem::Version.new(match[1]) > cutoff
        next
      end
      if line.match?(UNRELEASED_LINK_DEF)
        out << line.sub(%r{compare/v\d+\.\d+\.\d+\.\.\.HEAD}, "compare/v#{cutoff_string}...HEAD")
        next
      end
      if line.match?(LINK_DEF)
        out << line
        next
      end

      if line.match?(UNRELEASED_HEADING)
        out << line << ""
        dropping = true # empty the section; the blank line above stands in for its body
        next
      end
      if (match = line.match(VERSION_HEADING))
        dropping = Gem::Version.new(match[1]) > cutoff
        out << line unless dropping
        next
      end

      out << line unless dropping
    end

    out.join("\n")
      .sub(%r{(keepachangelog\.com/en/)\d+\.\d+\.\d+/}, "\\1#{page_version}/")
      .then { |result| result.end_with?("\n") ? result : "#{result}\n" }
  end
end
