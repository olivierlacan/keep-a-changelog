require "minitest/autorun"
require "stringio"
require_relative "../tools/changelog_release"

# A stand-in for ChangelogRelease::GitHubCli that records what it was asked to do
# and simulates release/tag state in memory, so the orchestration in Runner can
# be tested without touching the network or git.
class FakeGitHub
  attr_reader :created, :updated, :tags

  def initialize(releases: {}, tags: [])
    @releases = releases # tag => body
    @tags = tags
    @created = []
    @updated = []
  end

  def release_exists?(tag)
    @releases.key?(tag)
  end

  def release_body(tag)
    @releases.fetch(tag, "")
  end

  def tag_exists?(tag)
    @tags.include?(tag)
  end

  def create_tag(tag, message:, date:, sha:)
    @tags << tag
  end

  def create_release(tag:, title:, notes:)
    @releases[tag] = notes
    @created << {tag: tag, title: title, notes: notes}
  end

  def update_release_notes(tag:, notes:)
    @releases[tag] = notes
    @updated << {tag: tag, notes: notes}
  end
end

CHANGELOG_FIXTURE = <<~MARKDOWN
  # Changelog

  ## [Unreleased]

  ### Added

  - Something not released yet.

  ## [1.1.0] - 2019-02-15

  ### Added

  - Italian translation.
  - Indonesian translation.

  ## [1.0.0] - 2017-06-20

  ### Added

  - New visual identity.

  ### Changed

  - Start using "changelog" over "change log".

  ## [0.0.5] - 2014-12-13 [YANKED]

  ### Added

  - This one was pulled.

  [unreleased]: https://example.com/compare/v1.1.0...HEAD
  [1.1.0]: https://example.com/compare/v1.0.0...v1.1.0
MARKDOWN

class ChangelogReleaseParseTest < Minitest::Test
  def setup
    @entries = ChangelogRelease.parse(CHANGELOG_FIXTURE)
  end

  def test_parses_every_dated_version_newest_first
    assert_equal %w[v1.1.0 v1.0.0 v0.0.5], @entries.map(&:tag)
  end

  def test_skips_unreleased
    refute_includes @entries.map(&:version), "Unreleased"
  end

  def test_captures_version_tag_and_date
    latest = @entries.first
    assert_equal "1.1.0", latest.version
    assert_equal "v1.1.0", latest.tag
    assert_equal "2019-02-15", latest.date
  end

  def test_body_stops_before_next_heading
    assert_equal "### Added\n\n- Italian translation.\n- Indonesian translation.", @entries.first.notes
  end

  def test_last_entry_body_stops_before_link_definitions
    yanked = @entries.find { |entry| entry.tag == "v0.0.5" }
    assert_equal "### Added\n\n- This one was pulled.", yanked.notes
    refute_includes yanked.notes, "example.com"
  end

  def test_detects_yanked_marker_and_title
    yanked = @entries.find { |entry| entry.tag == "v0.0.5" }
    assert yanked.yanked
    assert_equal "0.0.5 [YANKED]", yanked.title
  end

  def test_non_yanked_title_is_just_the_version
    assert_equal "1.1.0", @entries.first.title
    refute @entries.first.yanked
  end

  def test_returns_empty_when_no_dated_version
    assert_empty ChangelogRelease.parse("# Changelog\n\n## [Unreleased]\n")
  end
end

class ChangelogReleaseNormalizeTest < Minitest::Test
  def test_line_endings_do_not_count_as_drift
    assert_equal ChangelogRelease.normalize("a\nb"), ChangelogRelease.normalize("a\r\nb")
  end

  def test_trailing_whitespace_ignored
    assert_equal ChangelogRelease.normalize("a\nb"), ChangelogRelease.normalize("a   \nb\t")
  end

  def test_leading_and_trailing_blank_lines_ignored
    assert_equal ChangelogRelease.normalize("a\nb"), ChangelogRelease.normalize("\n\na\nb\n\n")
  end

  def test_internal_blank_lines_preserved
    refute_equal ChangelogRelease.normalize("a\nb"), ChangelogRelease.normalize("a\n\nb")
  end

  def test_real_content_change_detected
    refute_equal(
      ChangelogRelease.normalize("- A thing."),
      ChangelogRelease.normalize("- A thing.\n- Italian translation.")
    )
  end
end

class ChangelogReleaseCreateTest < Minitest::Test
  def setup
    @entries = ChangelogRelease.parse(CHANGELOG_FIXTURE)
    @log = StringIO.new
  end

  def runner(github)
    ChangelogRelease::Runner.new(@entries, github: github, logger: @log)
  end

  def test_creates_release_and_tag_when_missing
    github = FakeGitHub.new
    assert runner(github).create_latest(sha: "abc123")

    assert_equal ["v1.1.0"], github.created.map { |c| c[:tag] }
    assert_equal "1.1.0", github.created.first[:title]
    assert_includes github.created.first[:notes], "Italian translation."
    assert_includes github.tags, "v1.1.0"
  end

  def test_does_nothing_when_release_exists
    github = FakeGitHub.new(releases: {"v1.1.0" => "whatever"})
    refute runner(github).create_latest(sha: "abc123")

    assert_empty github.created
  end

  def test_does_not_recreate_existing_tag
    github = FakeGitHub.new(tags: ["v1.1.0"])
    runner(github).create_latest(sha: "abc123")

    assert_equal ["v1.1.0"], github.tags # not duplicated
    assert_equal ["v1.1.0"], github.created.map { |c| c[:tag] }
  end
end

class ChangelogReleaseSyncTest < Minitest::Test
  def setup
    @entries = ChangelogRelease.parse(CHANGELOG_FIXTURE)
    @log = StringIO.new
  end

  def runner(github)
    ChangelogRelease::Runner.new(@entries, github: github, logger: @log)
  end

  def test_updates_release_whose_body_drifted
    # v1.1.0 is published without the translations that the changelog now lists.
    github = FakeGitHub.new(releases: {"v1.1.0" => "### Added\n"})
    updated = runner(github).sync_all

    assert_equal ["v1.1.0"], updated
    assert_includes github.updated.first[:notes], "Indonesian translation."
  end

  def test_leaves_matching_release_untouched
    matching = @entries.first.notes
    github = FakeGitHub.new(releases: {"v1.1.0" => matching})
    updated = runner(github).sync_all

    assert_empty updated
    assert_empty github.updated
  end

  def test_cosmetic_only_difference_is_not_drift
    # Same content, but with CRLF endings and a trailing blank line.
    cosmetic = @entries.first.notes.gsub("\n", "\r\n") + "\r\n\r\n"
    github = FakeGitHub.new(releases: {"v1.1.0" => cosmetic})
    updated = runner(github).sync_all

    assert_empty updated
  end

  def test_skips_versions_without_a_release
    github = FakeGitHub.new(releases: {"v1.1.0" => @entries.first.notes})
    runner(github).sync_all

    assert_empty github.updated # v1.0.0 and v0.0.5 have no release to reconcile
    assert_includes @log.string, "v1.0.0 — no release yet"
  end
end
