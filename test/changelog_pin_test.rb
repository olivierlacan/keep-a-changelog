require "minitest/autorun"
require_relative "../tools/changelog_pin"

# The version-pinned hero example: a spec page older than the published latest
# shows the project changelog as it stood at that track's last release, derived
# from the one live CHANGELOG.md. These tests pin the derivation rules against a
# fixture written from a hypothetical future (a 3.0.0 spec has shipped), then
# check the invariants that hold against the real CHANGELOG.md today.
class ChangelogPinPinnedTest < Minitest::Test
  # The newest release the changelog documents is 2.0.0.
  FIXTURE = <<~MD
    ## [Unreleased]
    ## [2.0.0] - 2026-06-07
    ## [1.1.2] - 2024-09-27
    ## [1.1.0] - 2019-02-15
  MD

  def test_pages_on_older_tracks_are_pinned
    # The 1.1.0 page pins as soon as the changelog records 2.0.0, regardless of
    # which version the site publishes as its default (the issue #720 report:
    # 1.x pages were showing the 2.0.0 example while 1.1.0 was still latest).
    assert ChangelogPin.pinned?(FIXTURE, "1.1.0")
    assert ChangelogPin.pinned?(FIXTURE, "1.0.0")
    assert ChangelogPin.pinned?(FIXTURE, "0.3.0")
  end

  def test_the_newest_documented_track_shows_the_live_changelog
    refute ChangelogPin.pinned?(FIXTURE, "2.0.0")
  end

  def test_patch_releases_stay_on_their_minor_track
    # A 2.0.1 entry must not pin the 2.0.0 page — same track.
    refute ChangelogPin.pinned?("## [2.0.1] - 2026-08-01\n", "2.0.0")
  end

  def test_a_draft_page_newer_than_every_entry_shows_the_live_changelog
    refute ChangelogPin.pinned?(FIXTURE, "3.0.0")
  end

  def test_a_changelog_with_no_dated_entries_never_pins
    refute ChangelogPin.pinned?("# Changelog\n", "1.0.0")
  end
end

class ChangelogPinTrackReleaseTest < Minitest::Test
  FIXTURE = <<~MD
    ## [Unreleased]
    ## [3.0.0] - 2027-01-01
    ## [2.0.10] - 2026-12-01
    ## [2.0.2] - 2026-08-01
    ## [2.0.0] - 2026-06-07
    ## [1.1.2] - 2024-09-27
  MD

  def test_pins_to_the_last_patch_of_the_track_not_the_minor_itself
    # 2.0.10 vs 2.0.2 also proves numeric (not lexical) version comparison.
    assert_equal "2.0.10", ChangelogPin.track_release(FIXTURE, "2.0.0")
  end

  def test_each_track_finds_its_own_newest_release
    assert_equal "3.0.0", ChangelogPin.track_release(FIXTURE, "3.0.0")
    assert_equal "1.1.2", ChangelogPin.track_release(FIXTURE, "1.1.0")
  end

  def test_a_track_with_no_recorded_release_returns_nil
    assert_nil ChangelogPin.track_release(FIXTURE, "1.0.0")
  end
end

class ChangelogPinPinTest < Minitest::Test
  # A future changelog: 3.0.0 has shipped, work is brewing in Unreleased, and
  # the 2.0.x track ended at 2.0.1. Pinning for the 2.0.0 page must reconstruct
  # the changelog as it stood at 2.0.1.
  FIXTURE = <<~MD
    # Changelog

    All notable changes to this project will be documented in this file.

    The format is based on [Keep a Changelog](https://keepachangelog.com/en/3.0.0/),
    and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

    ## [Unreleased]

    ### Added

    - Something brewing for the next release.

    ## [3.0.0] - 2027-01-01

    ### Changed

    - **Breaking:** everything, per the new conventions.

    ## [2.0.1] - 2026-08-01

    ### Fixed

    - Improve French translation.

    ## [2.0.0] - 2026-06-07

    ### Added

    - New guidance, contributed by [@someone].

    ## [1.1.2] - 2024-09-27

    ### Added

    - v1.1 German translation.

    [unreleased]: https://github.com/olivierlacan/keep-a-changelog/compare/v3.0.0...HEAD
    [3.0.0]: https://github.com/olivierlacan/keep-a-changelog/compare/v2.0.1...v3.0.0
    [2.0.1]: https://github.com/olivierlacan/keep-a-changelog/compare/v2.0.0...v2.0.1
    [2.0.0]: https://github.com/olivierlacan/keep-a-changelog/compare/v1.1.2...v2.0.0
    [1.1.2]: https://github.com/olivierlacan/keep-a-changelog/compare/v1.1.1...v1.1.2
    [@someone]: https://github.com/someone
  MD

  def pinned
    @pinned ||= ChangelogPin.pin(FIXTURE, "2.0.0")
  end

  def test_entries_newer_than_the_track_are_dropped
    refute_includes pinned, "[3.0.0] - 2027-01-01"
    refute_includes pinned, "**Breaking:** everything"
  end

  def test_the_track_and_everything_older_survive_intact
    assert_includes pinned, "## [2.0.1] - 2026-08-01"
    assert_includes pinned, "- Improve French translation."
    assert_includes pinned, "## [2.0.0] - 2026-06-07"
    assert_includes pinned, "## [1.1.2] - 2024-09-27"
    assert_includes pinned, "- v1.1 German translation."
  end

  def test_unreleased_keeps_its_heading_but_loses_its_contents
    # The Unreleased section is part of the format being taught, so the heading
    # stays; its entries describe work newer than the pinned track, so they go.
    assert_includes pinned, "## [Unreleased]"
    refute_includes pinned, "Something brewing"
  end

  def test_the_unreleased_compare_link_diffs_from_the_tracks_last_release
    assert_includes pinned, "[unreleased]: https://github.com/olivierlacan/keep-a-changelog/compare/v2.0.1...HEAD"
  end

  def test_dropped_entries_lose_their_link_definitions
    refute_includes pinned, "[3.0.0]:"
    assert_includes pinned, "[2.0.1]: https://github.com/olivierlacan/keep-a-changelog/compare/v2.0.0...v2.0.1"
  end

  def test_non_version_link_definitions_are_kept
    assert_includes pinned, "[@someone]: https://github.com/someone"
    assert_includes pinned, "[Semantic Versioning](https://semver.org/spec/v2.0.0.html)"
  end

  def test_the_preamble_points_at_the_pinned_spec_version
    assert_includes pinned, "https://keepachangelog.com/en/2.0.0/"
    refute_includes pinned, "https://keepachangelog.com/en/3.0.0/"
  end

  def test_no_release_on_the_track_returns_the_text_unchanged
    assert_equal FIXTURE, ChangelogPin.pin(FIXTURE, "1.0.0")
  end

  def test_the_emptied_unreleased_section_stays_well_formed
    assert_includes pinned, "## [Unreleased]\n\n## [2.0.1] - 2026-08-01"
  end
end

class ChangelogPinRealChangelogTest < Minitest::Test
  REAL = File.read(File.expand_path("../CHANGELOG.md", __dir__), encoding: "UTF-8")

  def test_the_1_1_page_pins_today
    # The live changelog documents 2.0.0, so every 1.x and 0.x page is pinned
    # right now — this is the fix for the issue #720 report.
    assert ChangelogPin.pinned?(REAL, "1.1.0")
    refute ChangelogPin.pinned?(REAL, "2.0.0")
  end

  def test_pinning_the_1_1_page_reconstructs_the_1_1_2_era
    pinned = ChangelogPin.pin(REAL, "1.1.0")

    refute_includes pinned, "## [2.0.0]"
    refute_includes pinned, "[2.0.0]:"
    assert_includes pinned, "## [1.1.2] - 2024-09-27"
    assert_includes pinned, "compare/v1.1.2...HEAD"
    assert_includes pinned, "https://keepachangelog.com/en/1.1.0/"
  end

  def test_pinning_the_latest_track_matches_the_live_changelog
    # While 2.0.x is the newest track, its pinned view and the live file must
    # agree (the live Unreleased section is empty between releases). This
    # guards the derivation against mangling text it shouldn't touch — if an
    # Unreleased entry is in flight, the only allowed difference is that the
    # pinned view empties that section.
    pinned = ChangelogPin.pin(REAL, "2.0.0")
    live_with_unreleased_emptied = REAL.sub(/(## \[Unreleased\]\n\n).*?(?=## \[)/m, '\1')
    assert_equal live_with_unreleased_emptied, pinned
  end
end
