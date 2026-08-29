require "minitest/autorun"
require_relative "../tools/prose_lint"

# The prose lint encodes docs/tone-and-voice.md so the English spec source is
# held to it in CI, not just by a reviewer's eye. These tests pin two things:
# the rules fire on known-bad prose, and the live 2.0 page passes clean (so the
# lint is a real gate, not decoration).
class ProseLintTest < Minitest::Test
  def ids(text)
    ProseLint.lint(text).map(&:rule)
  end

  def errors(text)
    ProseLint.lint(text).select { |f| f.severity == :error }
  end

  def test_flags_gatekeeping_words
    assert_includes ids("This is obviously fine."), "gatekeeping"
    assert_includes ids("You simply add a line."), "gatekeeping"
    assert_includes ids("Of course you know this."), "gatekeeping"
    assert_includes ids("It is trivially easy."), "gatekeeping"
  end

  def test_flags_ship_but_not_relationship
    assert_includes ids("You ship it on Friday."), "ship"
    assert_empty errors("The relationship between commits and entries.")
  end

  def test_flags_named_idioms
    assert_includes ids("When you cut a release, rename it."), "idiom"
    assert_includes ids("Check that the file is well-formed."), "well-formed"
  end

  def test_a_lone_em_dash_is_allowed_but_several_in_a_sentence_warn
    # A single em-dash is a legitimate break, not a finding.
    assert_empty ProseLint.lint("This is a break — a real one.")
    # Two or more in one sentence read as a bracketed aside a colon or commas
    # would replace: warn, never error.
    findings = ProseLint.lint("The tool — a small script — runs fine.")
    assert(findings.any? { |f| f.rule == "em-dash-aside" && f.severity == :warn })
    assert_empty findings.select { |f| f.severity == :error }
    # The aside count is measured per sentence, so one dash each in two
    # sentences stays clean.
    assert_empty ProseLint.lint("One break — here. Another break — there.")
  end

  def test_just_is_a_warning_not_an_error
    findings = ProseLint.lint("This is just a note.")
    assert(findings.any? { |f| f.rule == "just" && f.severity == :warn })
    assert_empty findings.select { |f| f.severity == :error }
  end

  def test_ignores_code_links_and_suppressed_lines
    # Banned words inside inline code or a URL are not prose.
    assert_empty errors("Use the `--ship` flag.")
    assert_empty errors("[guide](https://example.com/of-course) explains it.")
    # A fenced block is skipped entirely.
    fenced = "```\nyou simply ship it\n```\n"
    assert_empty errors(fenced)
    # The per-line marker suppresses that line.
    assert_empty errors("This is obviously fine. <!-- prose-lint-ignore -->")
  end

  def test_long_sentence_warns_but_enumerations_do_not
    run_on = (["word"] * 60).join(" ") + "."
    assert(ProseLint.lint(run_on).any? { |f| f.rule == "long-sentence" })

    enumeration = "Do this: " + (["a"] * 60).join("; ") + "."
    assert_empty ProseLint.lint(enumeration).select { |f| f.rule == "long-sentence" }
  end

  def test_the_live_2_0_page_is_clean
    findings = ProseLint.lint_file(File.expand_path("../source/en/2.0.0/index.html.md", __dir__))
    problems = findings.select { |f| f.severity == :error }
    assert_empty problems,
      "2.0 page has prose-lint errors:\n" +
        problems.map { |f| "  line #{f.line}: #{f.rule} \"#{f.match}\"" }.join("\n")
  end
end
