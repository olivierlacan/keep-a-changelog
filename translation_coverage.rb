#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'json'
require 'optparse'

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

  def initialize(options = {})
    @options = options
    @version_filter = options[:version]
    @language_filter = options[:language]
    @format = options[:format] || 'text'
    @show_details = options[:details]
    @migration = options[:migration]
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
    return migration_report if @migration

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

  def extract_sections(language, version)
    file_path = File.join(SOURCE_DIR, language, version, 'index.html.haml')

    return nil unless File.exist?(file_path)

    content = File.read(file_path, encoding: 'UTF-8')
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
    file_path = File.join(SOURCE_DIR, language, version, 'index.html.haml')
    return {} unless File.exist?(file_path)

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

  # Reduce a HAML line to its human-visible words.
  def normalize_fragment(line)
    s = line.dup
    s = s.sub(/^\s*%\w+(?:[#.][\w-]+)*/, '')          # leading %tag with #id/.class
    s = s.sub(/^\s*[.#][\w-]+(?:[#.][\w-]+)*/, '')    # or a leading .class/#id div
    s = s.gsub(/link_to\s+(["'])(.*?)\1[^}\n]*/m) { Regexp.last_match(2) } # keep link text
    s = s.tr('{}', '  ').delete('#')                  # drop interpolation punctuation
    s = s.sub(/^\s*=\s*/, ' ')                         # leading ruby eval marker
    s = s.gsub(/<[^>]+>/, '')                          # inline HTML tags, keep inner text
    s.gsub(/\s+/, ' ').strip
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
    # Cross-check: what the authored `new` / `updated` markers claim.
    markers  = marker_status_map(target)

    discrepancies = target_sections.filter_map do |sec|
      marked   = markers[sec]   || :unchanged
      detected = computed[sec]  || :unchanged
      next if marked == detected

      { section: sec, marked: marked, computed: detected }
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
  def print_annotation_check(discrepancies)
    puts "ANNOTATION CHECK (authored markers vs computed diff):"
    if discrepancies.empty?
      puts "  ✓ markers agree with the text diff for every section"
    else
      discrepancies.each do |d|
        puts "  ! #{d[:section]}: marked #{d[:marked]}, but text diff says #{d[:computed]}"
      end
    end
    puts
  end

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
