# frozen_string_literal: true

# Pure, framework-free prose lint for the English spec source. It enforces the
# rules in docs/tone-and-voice.md so they hold automatically instead of relying
# on a reviewer catching them, the way translation_coverage.rb --lint guards the
# translations. It reads the same Markdown a translator would, skips code and
# link machinery, and reports two severities:
#
#   :error  high-confidence tone or house-style breaks that should fail CI
#           ("ship" where "release" is meant, gatekeeping words the guide bans,
#           a handful of idioms it calls out by name)
#   :warn   context-dependent smells worth a human glance but not a build
#           failure on their own (a bare "just", a very long sentence, several
#           em-dashes piled into one sentence as bracketed asides)
#
# Scope is the 2.0+ Markdown pages (source/en/*/index.html.md). The older HAML
# pages keep the earlier, jokier voice on purpose (they are pinned to their era),
# so they are deliberately out of scope. Run via `bin/rake prose:lint`; the
# contract is pinned in test/prose_lint_test.rb.
#
# Suppress a single false positive by putting `<!-- prose-lint-ignore -->`
# anywhere on the offending line. The comment does not render in the built page.
module ProseLint
  Finding = Struct.new(:line, :severity, :rule, :match, :hint, keyword_init: true)

  IGNORE_MARKER = "prose-lint-ignore"

  # Only flag a long sentence past this many words, and never when it is a
  # semicolon-separated enumeration (those read as a list, not a run-on). The
  # threshold sits above the longest legitimate sentence on the 2.0 page so the
  # warning means something when it does fire.
  LONG_SENTENCE_WORDS = 45

  # Em-dashes are welcome for a genuine break. What reads poorly is piling
  # several into one sentence as bracketed asides, where a colon, commas, or
  # parentheses would be cleaner, so warn only past this many in one sentence.
  # A lone em-dash never fires.
  EM_DASH = "—"
  MAX_EM_DASHES_PER_SENTENCE = 1

  # Each rule: a matcher, a severity, a short id, and a hint naming the fix. The
  # matchers are case-insensitive and word-bounded so "relationship" never trips
  # the "ship" rule. Order is report order.
  RULES = [
    # --- Gatekeeping (guide principle 2): words that tell a reader they should
    # already understand. "just" is the same family but too common to fail on,
    # so it is a warning below. ---
    { id: "gatekeeping", severity: :error, re: /\bobvious(ly)?\b/i,
      hint: "gatekeeping; show it is simple with a short sentence instead" },
    { id: "gatekeeping", severity: :error, re: /\bsimply\b/i,
      hint: "gatekeeping; cut it or rephrase" },
    # "trivially" is the gatekeeping adverb the guide lists; a plain "trivial
    # change" means a minor one and is fine, so match only the adverb.
    { id: "gatekeeping", severity: :error, re: /\btrivially\b/i,
      hint: "gatekeeping; say what makes it small instead" },
    { id: "gatekeeping", severity: :error, re: /\bof course\b/i,
      hint: "gatekeeping; cut it" },
    { id: "gatekeeping", severity: :error, re: /\beveryone knows\b/i,
      hint: "gatekeeping; do not assume the reader knows" },
    { id: "gatekeeping", severity: :error, re: /\bas you(?:'d| would) expect\b/i,
      hint: "gatekeeping; state it plainly instead" },

    # --- Jargon and idioms the guide replaces with plain verbs. ---
    { id: "ship", severity: :error, re: /\bship(s|ped|ping)?\b/i,
      hint: "use 'release', not 'ship'" },
    { id: "well-formed", severity: :error, re: /\bwell-formed\b/i,
      hint: "use 'formatted correctly'" },
    { id: "idiom", severity: :error, re: /\bcut a release\b/i,
      hint: "idiom; use 'release a version' or 'at release time'" },
    { id: "idiom", severity: :error, re: /\bbolt(ed)? on\b/i,
      hint: "idiom; use 'add'" },
    { id: "idiom", severity: :error, re: /\bchase down\b/i,
      hint: "idiom; use 'find'" },
    { id: "idiom", severity: :error, re: /\bthe hook\b/i,
      hint: "metaphor; state the point plainly" },

    # --- Warnings: real but context-dependent. ---
    { id: "just", severity: :warn, re: /\bjust\b/i,
      hint: "often filler; if it means 'merely', cut it" },
    { id: "call-out", severity: :warn, re: /\bcall(s|ed|ing)? out\b/i,
      hint: "idiom; prefer 'highlight'" }
  ].freeze

  module_function

  # Lint one file. Returns an array of Finding, in file order.
  def lint_file(path)
    lint(File.read(path, encoding: "UTF-8"))
  end

  # Lint Markdown text. Skips fenced code blocks and link-reference definitions,
  # strips inline code spans and URLs from prose before matching (so a banned
  # word inside `code` or a link target is not flagged), and honors the
  # per-line ignore marker.
  def lint(text)
    findings = []
    in_fence = false

    text.each_line.with_index(1) do |raw, lineno|
      line = raw.chomp

      if line =~ /\A\s*(```|~~~)/
        in_fence = !in_fence
        next
      end
      next if in_fence
      next if line.include?(IGNORE_MARKER)
      next if link_definition?(line)

      prose = scrub(line)
      next if prose.strip.empty?

      RULES.each do |rule|
        prose.scan(rule[:re]) do
          findings << Finding.new(
            line: lineno, severity: rule[:severity], rule: rule[:id],
            match: Regexp.last_match(0), hint: rule[:hint]
          )
        end
      end

      long_sentences(prose).each do |sentence, words|
        findings << Finding.new(
          line: lineno, severity: :warn, rule: "long-sentence",
          match: "#{words} words", hint: truncate(sentence)
        )
      end

      dash_heavy_sentences(prose).each do |count|
        findings << Finding.new(
          line: lineno, severity: :warn, rule: "em-dash-aside",
          match: "#{count} em-dashes",
          hint: "several em-dashes in one sentence; a colon, commas, or parentheses may read cleaner"
        )
      end
    end

    findings
  end

  # A Markdown reference-link definition line, e.g. `[semver]: https://...`.
  def link_definition?(line)
    line.match?(/\A\s*\[[^\]]+\]:\s+\S/)
  end

  # Remove the parts of a prose line that are not authored prose: inline code
  # spans, autolinks/URLs, and the URL half of an inline `[text](url)` link
  # (the visible text stays). Leaves the rest for matching.
  def scrub(line)
    line
      .gsub(/`[^`]*`/, " ")            # inline code
      .gsub(/\]\([^)]*\)/, "] ")       # inline-link targets, keep the [text]
      .gsub(%r{https?://\S+}, " ")     # bare URLs
  end

  # Sentences over the word threshold, excluding semicolon enumerations. Returns
  # [sentence, word_count] pairs.
  def long_sentences(prose)
    prose.split(/(?<=[.!?])\s+/).filter_map do |sentence|
      next if sentence.count(";") >= 2 # a list, not a run-on
      words = sentence.split(/\s+/).count { |w| w =~ /[[:alpha:]]/ }
      [sentence, words] if words > LONG_SENTENCE_WORDS
    end
  end

  # Sentences leaning on em-dashes as bracketed asides. A lone em-dash is fine;
  # two or more in one sentence is the excessive apposition a colon or commas
  # usually replace. Returns the em-dash count for each offending sentence.
  def dash_heavy_sentences(prose)
    prose.split(/(?<=[.!?])\s+/).filter_map do |sentence|
      count = sentence.count(EM_DASH)
      count if count > MAX_EM_DASHES_PER_SENTENCE
    end
  end

  def truncate(str, max = 60)
    str.length > max ? "#{str[0, max].rstrip}..." : str
  end

  # Human-readable report for a set of [path, Finding] pairs.
  def format_findings(pairs)
    pairs.map do |path, f|
      "#{path}:#{f.line}: [#{f.severity}] #{f.rule}: \"#{f.match}\" — #{f.hint}"
    end.join("\n")
  end
end

if __FILE__ == $PROGRAM_NAME
  strict = ARGV.include?("--strict")
  paths = ARGV.reject { |a| a.start_with?("--") }
  paths = Dir["source/en/*/index.html.md"].sort if paths.empty?

  pairs = paths.flat_map { |p| ProseLint.lint_file(p).map { |f| [p, f] } }
  errors = pairs.count { |(_, f)| f.severity == :error }
  warns = pairs.count { |(_, f)| f.severity == :warn }

  puts ProseLint.format_findings(pairs) unless pairs.empty?
  summary = "prose-lint: #{errors} error(s), #{warns} warning(s) across #{paths.size} file(s)"
  puts(pairs.empty? ? "prose-lint: clean (#{paths.size} file(s))" : summary)

  exit 1 if errors.positive? || (strict && warns.positive?)
end
