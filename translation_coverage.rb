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
  VERSIONS = ['1.1.0', '1.0.0', '0.3.0'].freeze

  def initialize(options = {})
    @options = options
    @version_filter = options[:version]
    @language_filter = options[:language]
    @format = options[:format] || 'text'
    @show_details = options[:details]
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

    opts.on("-v", "--version VERSION", "Analyze specific version (1.1.0, 1.0.0, or 0.3.0)") do |v|
      options[:version] = v
    end

    opts.on("-l", "--language LANGUAGE", "Analyze specific language (e.g., es-ES, fr, de)") do |l|
      options[:language] = l
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
