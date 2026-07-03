# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../translation_coverage"

# The analyzer reads two page formats: HAML with %h3#id/%h4#id headings
# (0.3.0–1.1.0) and markdown with explicit {#id} kramdown anchors (2.0.0+).
# These tests pin both extractors and the --dashboard output against the real
# source tree, so a format change that silently drops a version from the
# coverage data fails here instead of shipping an empty dashboard.
class TranslationCoverageTest < Minitest::Test
  def analyzer(options = {})
    TranslationCoverageAnalyzer.new(options)
  end

  def test_extracts_sections_from_markdown_anchors
    sections = analyzer.send(:extract_sections, "en", "2.0.0")

    refute_nil sections, "en/2.0.0 (markdown source) should be analyzable"
    assert_includes sections, "what"
    assert_includes sections, "types"
    assert_operator sections.length, :>=, 20
  end

  def test_markdown_sections_skip_fenced_code_headings
    # The example changelog inside a fence contains "## [0.0.5] ..." lines;
    # only anchored headings outside fences may count as sections.
    sections = analyzer.send(:extract_sections, "en", "2.0.0")
    assert_equal sections.uniq, sections
    sections.each { |id| assert_match(/\A[\w-]+\z/, id) }
  end

  def test_still_extracts_sections_from_haml
    assert_equal 20, analyzer.send(:extract_sections, "en", "1.1.0").length
  end

  def test_markdown_section_texts_are_normalized
    texts = analyzer.send(:extract_section_texts, "en", "2.0.0")

    refute_empty texts
    what = texts["what"]
    refute_nil what
    assert_includes what, "changelog is a curated"
    refute_includes what, "{#"
    refute_includes what, "]("
  end

  def test_dashboard_embedding_api_is_public
    # config.rb builds /translations and /translations/progress from these two
    # methods on every site build; they must stay public.
    assert_respond_to analyzer, :dashboard_html
    assert_respond_to analyzer, :dashboard_data

    data = analyzer.dashboard_data
    assert_equal "1.1.0", data[:published_version]
    codes = data[:languages].map { |l| l[:code] }
    assert_includes codes, "fr"
    refute_includes codes, "en", "English is the baseline, not a translation"
  end

  def test_dashboard_output_is_self_contained_html
    Dir.mktmpdir do |dir|
      path = File.join(dir, "dashboard.html")
      capture_io { analyzer(dashboard: path).report }

      html = File.read(path, encoding: "UTF-8")
      refute_includes html, "__DASHBOARD_DATA__", "data placeholder must be substituted"
      assert_includes html, %("latest_version":"2.0.0")
      assert_includes html, %("published_version":"1.1.0")
      assert_includes html, "Français" # language names resolved from config.rb
      head = html[/<head>.*<\/head>/m]
      refute_match(/(?:src|href)="(?!data:)/, head, "no external assets (data: URIs are fine)")
      refute_match(/url\(/, head, "no external assets")
    end
  end
end
