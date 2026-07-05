require "minitest/autorun"

class BuildTest < Minitest::Test
  # Building is expensive, so it happens once for the whole class rather than
  # in a per-test setup.
  def self.output
    @output ||= `bin/rake build`
  end

  def test_build_succeeds
    assert_includes BuildTest.output, "Project built successfully."
  end

  # Every URL the version + language selectors emit must resolve within the
  # build. The dropdowns deliberately offer combinations with no real
  # translation (those land on a generated interstitial), and the dev server
  # papers over any gap by generating more pages than a production build —
  # which is exactly how /fr/2.0.0/ shipped as a 404: the language switcher on
  # the shipped English 2.0.0 draft linked 27 pages the build didn't contain,
  # and dev, generating interstitials for every version, never showed it.
  # Scanning the shipped HTML for the selectors' actual targets pins the
  # invariant without duplicating the exposure rules that decide them.
  def test_every_selector_option_resolves_in_the_build
    BuildTest.output
    pages = Dir.glob("build/**/index.html")
    refute_empty pages, "no built pages found — did the build run?"

    targets = pages.flat_map do |page|
      File.read(page).scan(/<option[^>]*\bvalue=['"]([^'"]+)['"]/).flatten
    end.uniq
    refute_empty targets, "no selector options found in the built pages"

    missing = targets.reject { |target| File.exist?("build/#{target}index.html") }
    assert_empty missing.map { |target| "/#{target}" },
      "selector options whose target page is not in the build"
  end
end
