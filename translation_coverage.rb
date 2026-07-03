#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'json'
require 'optparse'
require 'set'
require_relative 'tools/version_routing'

# Translation Coverage Analyzer for Keep a Changelog
# This utility analyzes which sections are translated in each language version
# and identifies missing translations compared to the English baseline.

class TranslationCoverageAnalyzer
  SOURCE_DIR = File.join(__dir__, 'source')

  # Known versions in order (newest first)
  VERSIONS = ['2.0.0', '1.1.0', '1.0.0', '0.3.0'].freeze

  # Latest version under development and the version it evolves from. The
  # `new` / `updated` CSS markers in the English LATEST_VERSION file describe how
  # each section changed relative to PREVIOUS_VERSION (see PR #600). The migration
  # report uses them to tell translators which sections to add, revise, or carry.
  LATEST_VERSION   = '2.0.0'
  PREVIOUS_VERSION = '1.1.0'

  # Sections renamed between PREVIOUS_VERSION and LATEST_VERSION (latest => previous).
  SECTION_RENAMES = { 'releases' => 'github-releases' }.freeze

  # HAML versions (newest first) used to find a version's predecessor for the
  # consistency audit. 0.3.0 is excluded: it uses translated markdown headings,
  # not stable section IDs, so it can't be diffed section-for-section.
  CONSISTENCY_VERSIONS = ['2.0.0', '1.1.0', '1.0.0'].freeze

  # Below this section-text similarity, a drift is "major" (likely a wholesale
  # re-translation) rather than a minor word-level tweak.
  MAJOR_DRIFT = 0.9

  # At or above this cross-text similarity to English, a translated section looks
  # like it was left untranslated (English pasted in). Non-Latin scripts score
  # near 0 against English, so this only fires on genuinely English-like target text.
  UNTRANSLATED_SIMILARITY = 0.95

  # Identifier-like tokens that should appear verbatim in every translation (they
  # are the literal section names users put in their own changelogs, not prose).
  # Flagged for review when present in the English section but missing from the
  # translation.
  GLOSSARY_TERMS = ['[YANKED]', 'Unreleased', 'CHANGELOG'].freeze

  # The six canonical change types — also identifier-like, checked separately so a
  # language that localizes them in prose is easy to spot.
  CHANGE_TYPE_TERMS = %w[Added Changed Deprecated Removed Fixed Security].freeze

  # Literal strings (release dates, semver versions) that must survive translation.
  LITERAL_PATTERNS = [/\b\d{4}-\d{2}-\d{2}\b/, /\bv?\d+\.\d+\.\d+\b/].freeze

  def initialize(options = {})
    @options = options
    @version_filter = options[:version]
    @language_filter = options[:language]
    @format = options[:format] || 'text'
    @show_details = options[:details]
    @migration = options[:migration]
    @consistency = options[:consistency]
    @segments = options[:segments]
    @lint = options[:lint]
    @strict_types = options[:strict_types]
    @dashboard = options[:dashboard]
  end

  def analyze
    results = {
      analyzed_at: Time.now.utc.strftime('%Y-%m-%d %H:%M:%S UTC'),
      versions: {}
    }

    versions_to_check.each do |version|
      results[:versions][version] = analyze_version(version)
    end

    results
  end

  def report
    return generate_dashboard if @dashboard
    return migration_report if @migration
    return consistency_report if @consistency
    return export_segments if @segments
    return lint_report if @lint

    results = analyze

    case @format
    when 'json'
      print_json_report(results)
    when 'csv'
      print_csv_report(results)
    else
      print_text_report(results)
    end
  end

  private

  def versions_to_check
    @version_filter ? [@version_filter] : VERSIONS
  end

  def analyze_version(version)
    english_sections = extract_sections('en', version)

    return nil if english_sections.nil?

    # Check if this version uses markdown (0.3.0) - sections won't have explicit IDs
    uses_markdown = version == '0.3.0'

    version_data = {
      baseline_sections: english_sections,
      section_count: english_sections.length,
      uses_markdown: uses_markdown,
      languages: {}
    }

    available_languages(version).each do |lang|
      next if lang == 'en' # Skip English baseline
      next if @language_filter && lang != @language_filter

      lang_sections = extract_sections(lang, version)
      next if lang_sections.nil?

      if uses_markdown
        # For markdown versions, compare by count only (headings are translated)
        coverage_pct = lang_sections.length == english_sections.length ? 100.0 :
                      (lang_sections.length.to_f / english_sections.length * 100).round(2)

        version_data[:languages][lang] = {
          section_count: lang_sections.length,
          complete_count: lang_sections.length,
          missing_count: english_sections.length - lang_sections.length,
          coverage_percentage: coverage_pct
        }
      else
        # For HAML versions with IDs, compare specific sections
        missing = english_sections - lang_sections
        extra = lang_sections - english_sections
        complete = lang_sections & english_sections

        coverage_pct = english_sections.empty? ? 0.0 : (complete.length.to_f / english_sections.length * 100).round(2)

        version_data[:languages][lang] = {
          sections: lang_sections,
          complete_count: complete.length,
          missing_count: missing.length,
          missing_sections: missing,
          extra_sections: extra,
          coverage_percentage: coverage_pct
        }
      end
    end

    version_data
  end

  # A version's page is HAML for 0.3.0–1.1.0 and markdown (with explicit {#id}
  # heading anchors) from 2.0.0 on. Both spellings are treated as the same page.
  def source_file(language, version)
    base = File.join(SOURCE_DIR, language, version)
    ['index.html.haml', 'index.html.md']
      .map { |name| File.join(base, name) }
      .find { |path| File.exist?(path) }
  end

  def markdown_source?(language, version)
    source_file(language, version)&.end_with?('.md')
  end

  def extract_sections(language, version)
    file_path = source_file(language, version)

    return nil if file_path.nil?

    content = File.read(file_path, encoding: 'UTF-8')
    return extract_markdown_anchor_sections(content) if file_path.end_with?('.md')

    sections = []

    # Extract h3 and h4 heading IDs (for versions 1.0.0+)
    # Pattern matches: %h3#section-id, %h4#section-id
    content.scan(/^\s*%h[34]#([\w-]+)/) do |match|
      sections << match[0]
    end

    # For version 0.3.0, extract markdown headings and generate IDs
    if sections.empty?
      content.scan(/^\s*###\s+(.+?)$/) do |match|
        heading = match[0].strip
        # Convert heading to slug (e.g., "What's a change log?" -> "whats-a-change-log")
        slug = heading.downcase
                      .gsub(/[''']/, '')  # Remove apostrophes
                      .gsub(/[^a-z0-9\s-]/, '')  # Remove non-alphanumeric except spaces and hyphens
                      .gsub(/\s+/, '-')  # Replace spaces with hyphens
                      .gsub(/-+/, '-')   # Replace multiple hyphens with single
                      .gsub(/^-|-$/, '')  # Remove leading/trailing hyphens
        sections << slug unless slug.empty?
      end
    end

    sections
  end

  # Section IDs of a markdown page: every ##–#### heading carrying an explicit
  # kramdown anchor ({#id}). Fenced code blocks are skipped so example changelog
  # headings inside them don't count as sections.
  def extract_markdown_anchor_sections(content)
    sections = []
    in_code = false

    content.each_line do |line|
      if line.match?(/^\s*(```|~~~)/)
        in_code = !in_code
        next
      end
      next if in_code

      sections << Regexp.last_match(1) if line =~ /^\#{2,4}\s+.*\{#([\w-]+)\}\s*$/
    end

    sections
  end

  def available_languages(version)
    Dir.glob(File.join(SOURCE_DIR, '*', version))
       .select { |path| File.directory?(path) }
       .map { |path| File.basename(File.dirname(path)) }
       .sort
  end

  # Classify each section of an English HAML file by how much it changed relative
  # to the previous version, using the `new` / `updated` CSS markers (PR #600).
  # Returns { section_id => { status:, updated:, new: } } where status is:
  #   :new       whole section is new (the heading itself carries `.new`)
  #   :updated   heading unchanged but the section has reworded/added content
  #   :unchanged no markers — translators can carry the previous translation over
  # Only the English LATEST_VERSION file carries these markers; others come back
  # as all-:unchanged, which is harmless.
  def extract_section_changes(language, version)
    file_path = File.join(SOURCE_DIR, language, version, 'index.html.haml')
    return {} unless File.exist?(file_path)

    changes = {}
    current = nil

    File.foreach(file_path, encoding: 'UTF-8') do |line|
      if (heading = line.match(/^\s*%h[34]#([\w-]+)/))
        current = heading[1]
        whole_new = section_marker(line) == :new
        changes[current] = { status: (whole_new ? :new : :unchanged), updated: 0, new: 0 }
        next
      end

      next unless current
      next if line.match?(/^\s*%a\.anchor/) # anchor helpers aren't content

      marker = section_marker(line)
      changes[current][marker] += 1 if marker
    end

    # A section with in-place markers but an unchanged heading counts as updated.
    changes.each_value do |c|
      c[:status] = :updated if c[:status] == :unchanged && (c[:updated] + c[:new]).positive?
    end

    changes
  end

  # Returns :new / :updated if the HAML element starting this line carries that
  # class (e.g. `%p.updated`, `%li.new`, `%h4#git.new`), otherwise nil.
  def section_marker(line)
    head = line[/^\s*([%.][\w#.\-]*)/, 1]
    return nil unless head
    return :new if head.match?(/\.new\b/)
    return :updated if head.match?(/\.updated\b/)

    nil
  end

  # Markers reduced to the migration vocabulary: { section_id => :new|:reworded|:unchanged }.
  def marker_status_map(version)
    extract_section_changes('en', version).transform_values do |c|
      c[:status] == :updated ? :reworded : c[:status]
    end
  end

  # Extract the translator-visible text of each section, keyed by section ID, so
  # two versions can be diffed by content rather than by which sections exist.
  # We drop HAML element tokens, anchors, interpolation wrappers and inline HTML,
  # keep the text of `link_to "..."` helpers, and collapse whitespace so that
  # reflowing or re-indenting a paragraph does NOT register as a change — only the
  # words do. Returns { section_id => "normalized text" }.
  def extract_section_texts(language, version)
    file_path = source_file(language, version)
    return {} if file_path.nil?
    return extract_markdown_section_texts(file_path) if file_path.end_with?('.md')

    texts = {}
    current = nil

    File.foreach(file_path, encoding: 'UTF-8') do |raw|
      line = raw.rstrip

      if (heading = line.match(/^\s*%h[34]#([\w-]+)/))
        current = heading[1]
        texts[current] ||= +''
        append_fragment(texts[current], line.sub(/^\s*%h[34]#[\w-]+(?:\.[\w-]+)*/, ''))
        next
      end

      # A top-level container div (column 0, e.g. `.press`) ends the current
      # section; anything before the next heading (like the title-less press
      # heading) is not section content.
      if line.match?(/^\.[\w-]/)
        current = nil
        next
      end

      next unless current
      next if line.match?(/^\s*%a\.anchor/) # anchor helpers aren't content

      append_fragment(texts[current], line)
    end

    texts.transform_values { |t| t.gsub(/\s+/, ' ').strip }
  end

  def append_fragment(buffer, line)
    frag = normalize_fragment(line)
    buffer << ' ' << frag unless frag.empty?
  end

  # Markdown counterpart of the HAML text extractor: the translator-visible words
  # of each anchored section, with front matter, link URLs, inline HTML, list
  # markers and emphasis punctuation stripped and whitespace collapsed.
  def extract_markdown_section_texts(file_path)
    lines = File.read(file_path, encoding: 'UTF-8').lines.map(&:rstrip)

    # Drop YAML front matter (--- ... --- at the very top of the file).
    if lines.first == '---' && (closing = lines[1..].index('---'))
      lines = lines[(closing + 2)..] || []
    end

    texts = {}
    current = nil
    in_code = false

    lines.each do |line|
      if line.match?(/^\s*(```|~~~)/)
        in_code = !in_code
        next
      end

      if !in_code && (heading = line.match(/^\#{2,4}\s+(.*?)\s*\{#([\w-]+)\}\s*$/))
        current = heading[2]
        texts[current] = +''
        texts[current] << normalize_markdown_fragment(heading[1])
        next
      end

      next unless current
      next if line.match?(/^\[[^\]]+\]:\s*\S/) # link reference definitions

      frag = in_code ? line.strip : normalize_markdown_fragment(line)
      texts[current] << ' ' << frag unless frag.empty?
    end

    texts.transform_values { |t| t.gsub(/\s+/, ' ').strip }
  end

  # Reduce a markdown line to its human-visible words.
  def normalize_markdown_fragment(line)
    s = line.dup
    s = s.gsub(/!\[([^\]]*)\]\([^)]*\)/, '\1')  # images -> alt text
    s = s.gsub(/\[([^\]]+)\]\([^)]*\)/, '\1')   # inline links -> link text
    s = s.gsub(/\[([^\]]+)\]\[[^\]]*\]/, '\1')  # reference links -> link text
    s = s.gsub(/<[^>]+>/, '') while s.match?(/<[^>]+>/) # inline HTML, keep inner text
    s = s.sub(/^\s*(?:[-*+]|\d+\.)\s+/, '')     # list markers
    s = s.tr('`*_', '')                          # code ticks / emphasis punctuation
    s.gsub(/\s+/, ' ').strip
  end

  # Reduce a HAML line to its human-visible words.
  def normalize_fragment(line)
    s = line.dup
    s = s.sub(/^\s*%\w+(?:[#.][\w-]+)*/, "")          # leading %tag with #id/.class
    s = s.sub(/^\s*[.#][\w-]+(?:[#.][\w-]+)*/, "")    # or a leading .class/#id div
    # keep the visible text of link_to "..." / '...' helpers (escaped quotes and
    # all), drop the trailing route/path arguments
    s = s.gsub(/link_to\s+"((?:\\.|[^"\\])*)"[^}\n]*/) { unescape(Regexp.last_match(1)) }
    s = s.gsub(/link_to\s+'((?:\\.|[^'\\])*)'[^}\n]*/) { unescape(Regexp.last_match(1)) }
    s = s.tr("{}", "  ").delete("#")                  # drop interpolation punctuation
    s = s.sub(/^\s*=\s*/, " ")                         # leading ruby eval marker
    s = s.gsub(/<[^>]+>/, "") while s.match?(/<[^>]+>/) # inline HTML tags, keep inner text (loop defeats nesting)
    s = s.delete("<>")                                 # drop any stray angle brackets
    s = s.gsub(/\s+([.,;:!?])/, '\1')                  # don't let markup leave a gap before punctuation
    s.gsub(/\s+/, " ").strip
  end

  def unescape(str)
    str.gsub(/\\(.)/, '\1')
  end

  # Language-agnostic similarity in [0.0, 1.0] via character-bigram Jaccard.
  # Robust for CJK and Latin text alike, and cheap (no edit-distance blowup), so
  # tiny normalization artifacts score ~1.0 while real rewrites score low.
  def text_similarity(a, b)
    return 1.0 if a == b
    return 0.0 if a.empty? || b.empty?

    ba = char_bigrams(a)
    bb = char_bigrams(b)
    return 0.0 if ba.empty? || bb.empty?

    (ba & bb).size.to_f / (ba | bb).size
  end

  def char_bigrams(str)
    chars = str.gsub(/\s+/, "").chars
    chars.each_cons(2).map(&:join).to_set
  end

  # Compute, by diffing English text, how each target-version section changed
  # relative to prev_version: :new (no counterpart), :reworded (text differs), or
  # :unchanged. Renamed sections are matched via SECTION_RENAMES.
  def compute_section_changes(prev_version, target_version)
    prev_texts   = extract_section_texts('en', prev_version)
    target_texts = extract_section_texts('en', target_version)

    target_texts.each_with_object({}) do |(id, text), result|
      prev_id = SECTION_RENAMES[id] || id
      result[id] =
        if !prev_texts.key?(prev_id) then :new
        elsif prev_texts[prev_id] != text then :reworded
        else :unchanged
        end
    end
  end

  # For each language, classify every section of the target version as work the
  # translator must do to upgrade their PREVIOUS_VERSION translation:
  #   add    — new section, or a changed section they never translated
  #   revise — section was reworded upstream and they have a prior translation
  #   carry  — section is unchanged; the prior translation can be reused as-is
  def migration_report
    target = @version_filter || LATEST_VERSION
    prev   = PREVIOUS_VERSION

    target_sections = extract_sections('en', target)
    abort("No English baseline found for #{target}") if target_sections.nil? || target_sections.empty?

    # Source of truth: diff the English text of every section between versions.
    computed = compute_section_changes(prev, target)
    # Cross-check: what the authored `new` / `updated` markers claim. Markdown
    # sources carry no markers, so the audit is skipped (nil) rather than
    # reporting every changed section as a spurious discrepancy.
    discrepancies =
      if markdown_source?('en', target)
        nil
      else
        markers = marker_status_map(target)
        target_sections.filter_map do |sec|
          marked   = markers[sec]   || :unchanged
          detected = computed[sec]  || :unchanged
          next if marked == detected

          { section: sec, marked: marked, computed: detected }
        end
      end

    langs = available_languages(prev).reject { |l| l == 'en' }
    langs.select! { |l| l == @language_filter } if @language_filter

    rows = langs.map do |lang|
      prev_sections = extract_sections(lang, prev) || []
      buckets = { add: [], revise: [], carry: [] }

      target_sections.each do |sec|
        status   = computed[sec] || :unchanged
        has_prev = prev_sections.include?(SECTION_RENAMES[sec] || sec)

        bucket =
          if status == :new
            :add
          elsif status == :reworded
            has_prev ? :revise : :add
          else
            has_prev ? :carry : :add
          end
        buckets[bucket] << sec
      end

      { lang: lang, buckets: buckets, work: buckets[:add].size + buckets[:revise].size }
    end

    print_migration_report(target, prev, target_sections, computed, rows, discrepancies)
  end

  def print_migration_report(target, prev, target_sections, computed, rows, discrepancies)
    new_secs      = target_sections.select { |s| computed[s] == :new }
    reworded_secs = target_sections.select { |s| computed[s] == :reworded }

    if @format == 'json'
      puts JSON.pretty_generate(
        target: target,
        previous: prev,
        method: 'computed-diff',
        change_surface: { new: new_secs, reworded: reworded_secs,
                          unchanged: target_sections - new_secs - reworded_secs },
        annotation_discrepancies: discrepancies,
        languages: rows.map do |r|
          { language: r[:lang], work_items: r[:work],
            add: r[:buckets][:add], revise: r[:buckets][:revise], carry: r[:buckets][:carry] }
        end
      )
      return
    end

    if @format == 'csv'
      puts "Language,Add,Revise,Carry,Work"
      rows.sort_by { |r| -r[:work] }.each do |r|
        puts [r[:lang], r[:buckets][:add].size, r[:buckets][:revise].size,
              r[:buckets][:carry].size, r[:work]].join(',')
      end
      return
    end

    puts "=" * 80
    puts "2.0 TRANSLATION MIGRATION  (#{prev} → #{target})"
    puts "Changes detected by diffing English section text (markers used only to audit)."
    puts "=" * 80
    puts "English #{target} has #{target_sections.size} sections: " \
         "#{new_secs.size} new, #{reworded_secs.size} reworded, " \
         "#{target_sections.size - new_secs.size - reworded_secs.size} unchanged."
    puts
    puts "  NEW (translate fresh):     #{new_secs.join(', ')}" unless new_secs.empty?
    puts "  REWORDED (revise):         #{reworded_secs.join(', ')}" unless reworded_secs.empty?
    puts
    puts "PER-LANGUAGE WORKLOAD (each language's #{prev} translation → #{target}):"
    puts "-" * 80
    printf "%-15s %6s %8s %7s %7s\n", "Language", "Add", "Revise", "Carry", "Work"
    puts "-" * 80
    rows.sort_by { |r| -r[:work] }.each do |r|
      printf "%-15s %6d %8d %7d %7d\n",
             r[:lang], r[:buckets][:add].size, r[:buckets][:revise].size,
             r[:buckets][:carry].size, r[:work]
    end
    puts "-" * 80
    puts

    print_annotation_check(discrepancies)

    if @show_details
      puts "WORK ITEMS BY LANGUAGE:"
      puts "-" * 80
      rows.sort_by { |r| -r[:work] }.each do |r|
        next if r[:work].zero?

        puts "#{r[:lang]}:"
        puts "  add:    #{r[:buckets][:add].join(', ')}"    unless r[:buckets][:add].empty?
        puts "  revise: #{r[:buckets][:revise].join(', ')}" unless r[:buckets][:revise].empty?
        puts
      end
    end
  end

  # Flag sections where the authored `new` / `updated` markers disagree with the
  # computed text diff — i.e. annotations that need fixing in the English source.
  # nil means the target is a markdown source, which carries no markers to audit.
  def print_annotation_check(discrepancies)
    puts "ANNOTATION CHECK (authored markers vs computed diff):"
    if discrepancies.nil?
      puts "  (skipped — the markdown source carries no new/updated markers)"
      puts
      return
    end
    if discrepancies.empty?
      puts "  ✓ markers agree with the text diff for every section"
    else
      discrepancies.each do |d|
        puts "  ! #{d[:section]}: marked #{d[:marked]}, but text diff says #{d[:computed]}"
      end
    end
    puts
  end

  # The HAML version immediately preceding `version`, or nil if none.
  def predecessor(version)
    i = CONSISTENCY_VERSIONS.index(version)
    return nil if i.nil? || i + 1 >= CONSISTENCY_VERSIONS.size

    CONSISTENCY_VERSIONS[i + 1]
  end

  # Audit each translation's *change pattern* against English's. Between two
  # reference English versions we know exactly which sections were added,
  # reworded, etc. A translation that has both versions should mirror that
  # pattern; where it doesn't, an inconsistency likely crept in:
  #   stale         English reworded a section, the translation did not follow
  #   drift         translation changed a section English left unchanged
  #   missing_new   English added a section the translation never added
  #   kept_removed  English removed a section the translation still carries
  def consistency_report
    target = @version_filter || PREVIOUS_VERSION
    prev   = predecessor(target)
    abort("No HAML predecessor to compare #{target} against") if prev.nil?

    eng = english_delta(prev, target)

    langs = (available_languages(prev) & available_languages(target)) - ['en']
    langs.select! { |l| l == @language_filter } if @language_filter

    rows = langs.map { |l| language_consistency(l, prev, target, eng) }
    print_consistency_report(target, prev, eng, rows)
  end

  # English section delta over the union of both versions' sections.
  def english_delta(prev, target)
    pt = extract_section_texts('en', prev)
    tt = extract_section_texts('en', target)

    (tt.keys | pt.keys).each_with_object({}) do |id, delta|
      prev_id = SECTION_RENAMES[id] || id
      in_prev = pt.key?(prev_id)
      in_tgt  = tt.key?(id)

      delta[id] =
        if in_prev && !in_tgt then :removed
        elsif in_tgt && !in_prev then :added
        elsif pt[prev_id] != tt[id] then :reworded
        else :unchanged
        end
    end
  end

  def language_consistency(lang, prev, target, eng)
    pt = extract_section_texts(lang, prev)
    tt = extract_section_texts(lang, target)
    issues = { stale: [], drift: [], missing_new: [], kept_removed: [] }

    eng.each do |id, estatus|
      prev_id = SECTION_RENAMES[id] || id
      lp = pt[prev_id]
      lt = tt[id]

      case estatus
      when :added
        issues[:missing_new] << id unless lt
      when :removed
        issues[:kept_removed] << id if lt
      when :reworded
        issues[:stale] << id if lp && lt && lp == lt
      when :unchanged
        issues[:drift] << { section: id, similarity: text_similarity(lp, lt) } if lp && lt && lp != lt
      end
    end

    { lang: lang, issues: issues }
  end

  def print_consistency_report(target, prev, eng, rows)
    changed = eng.reject { |_, v| v == :unchanged }

    if @format == 'json'
      puts JSON.pretty_generate(
        target: target,
        previous: prev,
        english_delta: changed,
        languages: rows.map do |r|
          { language: r[:lang],
            stale: r[:issues][:stale],
            drift: r[:issues][:drift].sort_by { |x| x[:similarity] },
            missing_new: r[:issues][:missing_new],
            kept_removed: r[:issues][:kept_removed] }
        end
      )
      return
    end

    puts "=" * 80
    puts "TRANSLATION CONSISTENCY  (#{prev} → #{target})"
    puts "Flags where a translation's change pattern diverges from English's."
    puts "=" * 80
    puts "English delta: " + (changed.empty? ? '(no sections changed)' : changed.map { |k, v| "#{k}=#{v}" }.join(', '))
    puts
    puts "  stale = English reworded the section, but the translation did not follow"
    puts "  drift = translation changed a section English left unchanged"
    puts "          (major = similarity < #{MAJOR_DRIFT}, likely a re-translation)"
    puts "  miss  = English added a section the translation never added"
    puts "  kept  = English removed a section the translation still carries"
    puts
    printf "%-15s %6s %14s %6s %6s\n", 'Language', 'Stale', 'Drift maj/min', 'Miss', 'Kept'
    puts "-" * 80
    ordered = rows.sort_by { |r| -consistency_weight(r) }
    ordered.each do |r|
      d = r[:issues][:drift]
      maj = d.count { |x| x[:similarity] < MAJOR_DRIFT }
      printf "%-15s %6d %14s %6d %6d\n",
             r[:lang], r[:issues][:stale].size, "#{maj}/#{d.size - maj}",
             r[:issues][:missing_new].size, r[:issues][:kept_removed].size
    end
    puts "-" * 80
    puts

    if @show_details
      ordered.each do |r|
        i = r[:issues]
        next if i.values.all?(&:empty?)

        puts "#{r[:lang]}:"
        puts "  stale:        #{i[:stale].join(', ')}" unless i[:stale].empty?
        puts "  missing-new:  #{i[:missing_new].join(', ')}" unless i[:missing_new].empty?
        puts "  kept-removed: #{i[:kept_removed].join(', ')}" unless i[:kept_removed].empty?
        unless i[:drift].empty?
          puts "  drift (similarity — lower means more changed):"
          i[:drift].sort_by { |x| x[:similarity] }.each do |x|
            printf "    %.2f  %s\n", x[:similarity], x[:section]
          end
        end
        puts
      end
    end

    total = rows.sum { |r| consistency_weight(r) }
    puts "#{total} potential inconsistencies across #{rows.size} languages."
    puts "Drift is often legitimate polishing — review by magnitude (run with --details)."
  end

  def consistency_weight(row)
    i = row[:issues]
    i[:stale].size + i[:drift].size + i[:missing_new].size + i[:kept_removed].size
  end

  # --- Parallel segment export -------------------------------------------------
  # Emit aligned English<->translation pairs (one per section) so any external,
  # auditable QA tool (pofilter, LanguageTool, Weblate, COMET-Kiwi, LaBSE...) can
  # consume them. Alignment is by stable section ID, so it's deterministic.

  def segments_for(version)
    en = extract_section_texts('en', version)
    langs = available_languages(version).reject { |l| l == 'en' }
    langs.select! { |l| l == @language_filter } if @language_filter

    langs.flat_map do |lang|
      target = extract_section_texts(lang, version)
      en.keys.select { |id| target.key?(id) }.map do |id|
        { language: lang, version: version, section: id, source: en[id], target: target[id] }
      end
    end
  end

  def export_segments
    version = @version_filter || PREVIOUS_VERSION
    segs = segments_for(version)

    case @format
    when 'po'  then print_segments_po(segs)
    when 'csv' then print_segments_csv(segs)
    else            print_segments_jsonl(segs) # default: one JSON object per line
    end
  end

  def print_segments_jsonl(segs)
    segs.each { |s| puts JSON.generate(s) }
  end

  def print_segments_csv(segs)
    puts "language,version,section,source,target"
    segs.each do |s|
      puts [s[:language], s[:version], s[:section],
            %("#{s[:source].gsub('"', '""')}"), %("#{s[:target].gsub('"', '""')}")].join(',')
    end
  end

  def print_segments_po(segs)
    puts '# Keep a Changelog — parallel segments for translation QA.'
    puts '# msgid = English source, msgstr = translation, one entry per section.'
    puts 'msgid ""'
    puts 'msgstr ""'
    puts '"Content-Type: text/plain; charset=UTF-8\n"'
    puts
    segs.each do |s|
      puts "#: #{s[:language]}/#{s[:version]}##{s[:section]}"
      puts "msgctxt #{po_quote("#{s[:language]}:#{s[:section]}")}"
      puts "msgid #{po_quote(s[:source])}"
      puts "msgstr #{po_quote(s[:target])}"
      puts
    end
  end

  def po_quote(str)
    # Escape everything in one pass (a hash replacement is literal, so there's no
    # order dependency between escaping backslashes and the characters that need a
    # backslash added). Covers the PO-relevant control characters too.
    escaped = str.to_s.gsub(/[\\"\t\n\r]/,
      "\\" => "\\\\", "\"" => "\\\"", "\t" => "\\t", "\n" => "\\n", "\r" => "\\r")
    %("#{escaped}")
  end

  # --- Deterministic lint ------------------------------------------------------
  # Rule-based, fully explainable checks comparing each translated section to its
  # English source. Catches mechanical defects (no model, no judgement calls):
  # untranslated text, dropped identifier-like terms, missing dates/versions, and
  # link-count mismatches.

  def lint_report
    version  = @version_filter || PREVIOUS_VERSION
    en       = extract_section_texts('en', version)
    en_links = section_link_counts('en', version)

    langs = available_languages(version).reject { |l| l == 'en' }
    langs.select! { |l| l == @language_filter } if @language_filter

    findings = langs.flat_map do |lang|
      target   = extract_section_texts(lang, version)
      t_links  = section_link_counts(lang, version)
      lint_language(lang, en, target, en_links, t_links)
    end

    print_lint_report(version, langs, findings)
  end

  def lint_language(lang, en, target, en_links, t_links)
    found = []
    en.each do |id, src|
      tgt = target[id]
      next unless tgt # absent sections are a coverage concern, not a lint concern

      sim = text_similarity(src, tgt)
      if sim >= UNTRANSLATED_SIMILARITY
        found << finding(lang, id, 'untranslated', "similarity to English #{sim.round(2)} ≥ #{UNTRANSLATED_SIMILARITY}")
      end

      GLOSSARY_TERMS.each do |term|
        found << finding(lang, id, 'missing-term', "English term #{term.inspect} not present") if src.include?(term) && !tgt.include?(term)
      end

      # Localizing the canonical change types is an accepted per-language choice
      # by default; --strict-types opts into flagging it for projects that want
      # the English headers kept verbatim everywhere.
      if @strict_types
        CHANGE_TYPE_TERMS.each do |term|
          found << finding(lang, id, 'localized-type', "change-type #{term.inspect} not kept verbatim") if src.include?(term) && !tgt.include?(term)
        end
      end

      LITERAL_PATTERNS.each do |re|
        src.scan(re).uniq.each do |lit|
          found << finding(lang, id, 'missing-literal', "#{lit.inspect} not present") unless tgt.include?(lit)
        end
      end

      ec = en_links[id] || 0
      tc = t_links[id] || 0
      found << finding(lang, id, 'link-count', "English has #{ec} link(s), translation has #{tc}") if ec != tc
    end
    found
  end

  def finding(lang, section, kind, detail)
    { language: lang, section: section, kind: kind, detail: detail }
  end

  # Count links per section: `link_to` helpers in a HAML file, inline and
  # reference-style markdown links (but not images) in a markdown file.
  def section_link_counts(language, version)
    path = source_file(language, version)
    return {} if path.nil?
    return markdown_section_link_counts(path) if path.end_with?('.md')

    counts = Hash.new(0)
    current = nil
    File.foreach(path, encoding: 'UTF-8') do |line|
      if (m = line.match(/^\s*%h[34]#([\w-]+)/))
        current = m[1]
        counts[current] += 0
        next
      end
      if line.match?(/^\.[\w-]/)
        current = nil
        next
      end
      next unless current

      counts[current] += line.scan(/link_to/).size
    end
    counts
  end

  def markdown_section_link_counts(path)
    counts = Hash.new(0)
    current = nil
    in_code = false
    File.foreach(path, encoding: 'UTF-8') do |line|
      if line.match?(/^\s*(```|~~~)/)
        in_code = !in_code
        next
      end
      next if in_code

      if (m = line.match(/^\#{2,4}\s+.*\{#([\w-]+)\}\s*$/))
        current = m[1]
        counts[current] += 0
        next
      end
      next unless current
      next if line.match?(/^\[[^\]]+\]:\s*\S/) # link reference definitions

      counts[current] += line.scan(/(?<!!)\[[^\]]+\](?:\([^)]*\)|\[[^\]]*\])/).size
    end
    counts
  end

  def print_lint_report(version, langs, findings)
    if @format == 'json'
      puts JSON.pretty_generate(version: version, findings: findings)
      return
    end

    if @format == 'csv'
      puts "language,section,kind,detail"
      findings.each { |f| puts [f[:language], f[:section], f[:kind], %("#{f[:detail].gsub('"', '""')}")].join(',') }
      return
    end

    kinds  = lint_kinds
    labels = { 'untranslated' => 'untrans', 'localized-type' => 'loc-type',
               'missing-term' => 'term', 'missing-literal' => 'lit', 'link-count' => 'links' }
    legend = { 'untranslated'    => "section text is ~identical to English (≥ #{UNTRANSLATED_SIMILARITY} similarity)",
               'localized-type'  => "a canonical change type (Added/Changed/…) was not kept verbatim",
               'missing-term'    => "[YANKED]/Unreleased/CHANGELOG present in English but absent",
               'missing-literal' => "a date or version present in English is absent",
               'link-count'      => "the number of links differs from English" }

    puts "=" * 80
    puts "TRANSLATION LINT  (en/#{version} vs each translation)"
    puts "Deterministic, rule-based checks — every flag below is mechanical and exact."
    puts "=" * 80
    kinds.each { |k| printf "  %-14s %s\n", k, legend[k] }
    puts

    printf "%-12s", "Language"
    kinds.each { |k| printf " %9s", labels[k] }
    puts
    puts "-" * 80
    langs.sort.each do |lang|
      lf = findings.select { |f| f[:language] == lang }
      next if lf.empty?

      printf "%-12s", lang
      kinds.each { |k| printf " %9d", lf.count { |f| f[:kind] == k } }
      puts
    end
    puts "-" * 80
    puts

    by_kind = findings.group_by { |f| f[:kind] }
    puts "Totals by kind: " + (by_kind.empty? ? "(none)" : by_kind.map { |k, v| "#{k}=#{v.size}" }.join(", "))
    puts "(change-type localization is accepted by policy; run --strict-types to flag it.)" unless @strict_types
    puts

    if @show_details
      findings.group_by { |f| f[:language] }.sort.each do |lang, fs|
        puts "#{lang}:"
        fs.each { |f| puts "  [#{f[:kind]}] #{f[:section]}: #{f[:detail]}" }
        puts
      end
    end
  end

  def lint_kinds
    kinds = ['untranslated']
    kinds << 'localized-type' if @strict_types
    kinds + ['missing-term', 'missing-literal', 'link-count']
  end

  # --- Static dashboard ----------------------------------------------------
  # Render the coverage analysis into a single self-contained HTML file: the
  # data is embedded as JSON in tools/dashboard_template.html, so the result
  # opens directly in a browser (file://) with no server and no network access.

  DASHBOARD_TEMPLATE = File.join(__dir__, 'tools', 'dashboard_template.html')
  DASHBOARD_OUTPUT   = File.join(__dir__, 'translation-dashboard.html')

  def generate_dashboard
    output = @dashboard.is_a?(String) ? @dashboard : DASHBOARD_OUTPUT
    File.write(output, dashboard_html, encoding: 'UTF-8')
    puts "Wrote #{output} — open it directly in a browser, no server needed."
  end

  # The complete self-contained dashboard page as a string. Public (see the
  # `public` declarations at the bottom of the class) so config.rb can embed it
  # as the /translations/progress page on every site build.
  def dashboard_html
    template = File.read(DASHBOARD_TEMPLATE, encoding: 'UTF-8')
    json = JSON.generate(dashboard_data, script_safe: true)
    html = template.sub('__DASHBOARD_DATA__') { json }

    abort("Template placeholder __DASHBOARD_DATA__ not found in #{DASHBOARD_TEMPLATE}") if html == template

    html
  end

  def dashboard_data
    results = analyze
    names = language_names

    versions = VERSIONS.filter_map do |v|
      data = results[:versions][v]
      next if data.nil?

      { version: v,
        sections: data[:section_count],
        id_based: !data[:uses_markdown],
        published: Gem::Version.new(v) <= Gem::Version.new(VersionRouting::PUBLISHED_VERSION) }
    end

    codes = results[:versions].values.compact.flat_map { |d| d[:languages].keys }.uniq.sort

    languages = codes.map do |code|
      cells = versions.each_with_object({}) do |ver, h|
        info = results[:versions][ver[:version]]&.dig(:languages, code)
        next unless info

        h[ver[:version]] = { coverage: info[:coverage_percentage],
                             complete: info[:complete_count],
                             missing: info[:missing_count],
                             missing_sections: info[:missing_sections] || [] }
      end

      { code: code, name: names[code] || code, versions: cells }
    end

    { generated_at: Time.now.utc.strftime('%Y-%m-%d %H:%M UTC'),
      latest_version: LATEST_VERSION,
      published_version: VersionRouting::PUBLISHED_VERSION,
      versions: versions,
      languages: languages }
  end

  # Human-readable language names, read from the $languages map in config.rb so
  # the dashboard never needs its own copy. Codes missing there (e.g. `id`,
  # which only exists as `id-ID` in config) fall back to a base-code match, then
  # to the code itself.
  def language_names
    config_path = File.join(__dir__, 'config.rb')
    return {} unless File.exist?(config_path)

    names = {}
    current = nil
    File.foreach(config_path, encoding: 'UTF-8') do |line|
      if (entry = line.match(/^\s*"([\w-]+)"\s*=>\s*\{/))
        current = entry[1]
      elsif current && (name = line.match(/^\s*name:\s*"([^"]+)"/))
        names[current] = name[1]
        current = nil
      end
    end

    names.default_proc = proc do |hash, code|
      base = code.split('-').first
      match = hash.keys.find { |k| k.split('-').first == base }
      match && hash[match]
    end
    names
  end

  # The embedding surface for the Middleman site (config.rb): the finished
  # dashboard page and the raw analysis data behind it.
  public :dashboard_html, :dashboard_data

  def print_text_report(results)
    puts "=" * 80
    puts "TRANSLATION COVERAGE REPORT"
    puts "Generated: #{results[:analyzed_at]}"
    puts "=" * 80
    puts

    results[:versions].each do |version, data|
      next if data.nil?

      print_version_report(version, data)
    end
  end

  def print_version_report(version, data)
    puts "-" * 80
    puts "VERSION: #{version}"
    puts "-" * 80
    puts "Baseline (English) has #{data[:section_count]} sections"

    if data[:uses_markdown]
      puts "Note: This version uses markdown format with translated headings."
      puts "Coverage is based on section count, not specific section IDs."
    end
    puts

    if @show_details && !data[:uses_markdown]
      puts "Sections: " + data[:baseline_sections].join(", ")
      puts
    end

    if data[:languages].empty?
      puts "No translations found for this version."
      puts
      return
    end

    # Summary table
    puts
    puts "COVERAGE SUMMARY:"
    puts "-" * 80
    printf "%-15s %10s %10s %12s\n", "Language", "Complete", "Missing", "Coverage"
    puts "-" * 80

    sorted_languages = data[:languages].sort_by { |_, info| -info[:coverage_percentage] }

    sorted_languages.each do |lang, info|
      status_indicator = case info[:coverage_percentage]
                        when 100 then "✓"
                        when 75..99 then "●"
                        when 50..74 then "◐"
                        else "○"
                        end

      printf "%-15s %8d   %8d   %9.1f%% %s\n",
             lang,
             info[:complete_count],
             info[:missing_count],
             info[:coverage_percentage],
             status_indicator
    end
    puts "-" * 80
    puts

    # Detailed missing sections (only for non-markdown versions)
    if @show_details && !data[:uses_markdown]
      puts "MISSING SECTIONS BY LANGUAGE:"
      puts "-" * 80

      sorted_languages.each do |lang, info|
        next if info[:missing_sections].nil? || info[:missing_sections].empty?

        puts "#{lang}:"
        info[:missing_sections].each do |section|
          puts "  - #{section}"
        end

        unless info[:extra_sections].nil? || info[:extra_sections].empty?
          puts "  Extra sections (not in English):"
          info[:extra_sections].each do |section|
            puts "    + #{section}"
          end
        end
        puts
      end
      puts
    end

    # Summary statistics
    total_translations = data[:languages].count

    if total_translations > 0
      complete_translations = data[:languages].count { |_, info| info[:coverage_percentage] == 100 }
      avg_coverage = data[:languages].values.sum { |info| info[:coverage_percentage] } / total_translations

      puts "STATISTICS:"
      puts "  Total translations: #{total_translations}"
      puts "  Complete (100%): #{complete_translations}"
      puts "  Partial: #{total_translations - complete_translations}"
      puts "  Average coverage: #{avg_coverage.round(2)}%"
      puts
    end
  end

  def print_json_report(results)
    puts JSON.pretty_generate(results)
  end

  def print_csv_report(results)
    puts "Version,Language,Complete,Missing,Total,Coverage %"

    results[:versions].each do |version, data|
      next if data.nil?

      data[:languages].each do |lang, info|
        puts [
          version,
          lang,
          info[:complete_count],
          info[:missing_count],
          data[:section_count],
          info[:coverage_percentage]
        ].join(',')
      end
    end
  end
end

# CLI Interface
if __FILE__ == $PROGRAM_NAME
  options = {}

  OptionParser.new do |opts|
    opts.banner = "Usage: translation_coverage.rb [options]"
    opts.separator ""
    opts.separator "Analyzes translation coverage for Keep a Changelog"
    opts.separator ""
    opts.separator "Options:"

    opts.on("-v", "--version VERSION", "Analyze specific version (2.0.0, 1.1.0, 1.0.0, or 0.3.0)") do |v|
      options[:version] = v
    end

    opts.on("-l", "--language LANGUAGE", "Analyze specific language (e.g., es-ES, fr, de)") do |l|
      options[:language] = l
    end

    opts.on("-m", "--migration", "Show 2.0 migration workload: which sections each",
            "  language must add, revise (reworded upstream), or carry over") do
      options[:migration] = true
    end

    opts.on("-c", "--consistency", "Audit each translation's change pattern against",
            "  English's between reference versions (stale / drift / miss / kept)") do
      options[:consistency] = true
    end

    opts.on("--lint", "Deterministic, rule-based QA: untranslated text, dropped",
            "  terms/dates/versions, link-count mismatches") do
      options[:lint] = true
    end

    opts.on("--strict-types", "With --lint, also flag change-type headers",
            "  (Added/Changed/…) that were localized instead of kept verbatim") do
      options[:strict_types] = true
    end

    opts.on("--segments", "Export aligned en<->translation segments for external QA",
            "  tools (use --format jsonl [default], csv, or po)") do
      options[:segments] = true
    end

    opts.on("--dashboard [PATH]", "Write a self-contained HTML dashboard of coverage",
            "  across languages and versions (default: translation-dashboard.html)") do |path|
      options[:dashboard] = path || true
    end

    opts.on("-f", "--format FORMAT", "Output format: text (default), json, or csv") do |f|
      options[:format] = f
    end

    opts.on("-d", "--details", "Show detailed section-by-section breakdown") do
      options[:details] = true
    end

    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
  end.parse!

  analyzer = TranslationCoverageAnalyzer.new(options)
  analyzer.report
end
