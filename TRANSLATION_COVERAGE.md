# Translation Coverage Tool

A utility for analyzing translation completeness across different language versions of Keep a Changelog.

## Overview

This tool helps maintainers track which sections have been translated in each language and identify missing translations. It analyzes the HAML files across all language directories and versions, comparing them against the English baseline.

## Features

- **Section-by-section analysis** for versions with explicit section IDs (1.0.0+)
- **Section count comparison** for markdown-based versions (0.3.0)
- **Multiple output formats**: text (default), JSON, CSV
- **Filter by version** or specific language
- **Visual indicators** for translation completeness:
  - ✓ = 100% complete
  - ● = 75-99% complete
  - ◐ = 50-74% complete
  - ○ = 0-49% complete

## Usage

### Basic Usage

Show coverage for all versions and languages:

```bash
ruby translation_coverage.rb
```

### Filter by Version

Analyze a specific version:

```bash
ruby translation_coverage.rb --version 1.1.0
ruby translation_coverage.rb --version 1.0.0
ruby translation_coverage.rb --version 0.3.0
```

### Filter by Language

Analyze a specific language across all versions:

```bash
ruby translation_coverage.rb --language fr
ruby translation_coverage.rb --language es-ES
ruby translation_coverage.rb --language zh-CN
```

### Combine Filters

Check a specific language in a specific version:

```bash
ruby translation_coverage.rb --version 1.1.0 --language pt-BR
```

### Show Detailed Information

Include section-by-section breakdown and list missing sections:

```bash
ruby translation_coverage.rb --details
ruby translation_coverage.rb --version 1.1.0 --details
```

### Output Formats

#### CSV Format

Perfect for importing into spreadsheets:

```bash
ruby translation_coverage.rb --format csv > coverage.csv
```

Output format:
```csv
Version,Language,Complete,Missing,Total,Coverage %
1.1.0,cs,20,0,20,100.0
1.1.0,da,20,0,20,100.0
...
```

#### JSON Format

For programmatic processing:

```bash
ruby translation_coverage.rb --format json > coverage.json
```

#### Text Format (Default)

Human-readable report with statistics:

```bash
ruby translation_coverage.rb --format text
```

## Migration Mode: tracking reworded sections

Plain coverage only answers *"which sections is a translation missing?"* It can't
see that an existing section was **reworded** in a newer version — the section ID
is still present, so it looks complete even though the text is now out of date.

Migration mode closes that gap. It **diffs the English text** of every section
between the previous version (`1.1.0`) and the target (`2.0.0`) and classifies
each as **new**, **reworded**, or **unchanged**. The text is normalized first —
HAML element tokens, anchors, interpolation and inline HTML are stripped while
`link_to "..."` text is kept, and whitespace is collapsed — so reflowing or
re-indenting a paragraph does *not* register as a change; only the words do.

The English `2.0.0` source also marks changed paragraphs with `new` / `updated`
CSS classes (see PR #600). Those markers are **not** the source of truth here —
instead the tool **audits** them against the computed diff and reports any section
where the annotation and the actual text disagree (see "Annotation check" below),
which helps keep the markup honest as the draft evolves.

```bash
ruby translation_coverage.rb --migration
```

For each language it then reports the work needed to bring its `1.1.0` translation
up to `2.0.0`:

- **Add** — a brand-new section (e.g. `git`), or a changed section the language
  never translated.
- **Revise** — a section that was reworded upstream and already has a prior
  translation to update.
- **Carry** — an unchanged section; the existing translation can be reused as-is.

```
2.0 TRANSLATION MIGRATION  (1.1.0 → 2.0.0)
Changes detected by diffing English section text (markers used only to audit).
English 2.0.0 has 21 sections: 1 new, 11 reworded, 9 unchanged.
  NEW (translate fresh):     git
  REWORDED (revise):         what, why, principles, effort, ...

Language           Add   Revise   Carry    Work
fr                   1       11       9      12

ANNOTATION CHECK (authored markers vs computed diff):
  ✓ markers agree with the text diff for every section
```

Add `--details` to list the exact section IDs per language, `--language LANG` to
focus on one, or `--format json` / `--format csv` to export. Renamed sections
(e.g. `github-releases` → `releases`) are mapped to their previous IDs so they
count as **revise**, not a spurious add/remove.

### Annotation check

Because the diff is computed from text, it can verify the hand-applied
`new` / `updated` CSS markers. If a section's text changed but it was never
marked (or was marked but the text is identical), it appears under
`ANNOTATION CHECK` so you can fix the markup. A clean run prints a single ✓.

> Note: the report is meaningful for the `1.1.0 → 2.0.0` upgrade, since that's the
> version pair being diffed. Pass `--version` to target a different version whose
> English source exists.

## Understanding the Output

### Version 1.1.0 and 1.0.0

These versions use HAML with explicit section IDs. The tool can identify exactly which sections are missing.

**Sections in 1.1.0 (20 total):**
- what, why, who, how, principles, types, effort
- bad-practices, log-diffs, ignoring-deprecations, confusing-dates, inconsistent-changes
- frequently-asked-questions, standard, filename, github-releases, automatic, yanked, rewrite, contribute

**Sections in 1.0.0 (19 total):**
Same as 1.1.0 but without `inconsistent-changes`

### Version 0.3.0

This version uses markdown blocks with translated headings, so sections cannot be compared by ID. The tool compares section counts instead:

**Sections in 0.3.0 (14 total):**
All headings are translated, so coverage is based on whether the translation has the same number of sections as English.

## Example Output

```
================================================================================
TRANSLATION COVERAGE REPORT
Generated: 2026-01-07 18:55:49 UTC
================================================================================

--------------------------------------------------------------------------------
VERSION: 1.1.0
--------------------------------------------------------------------------------
Baseline (English) has 20 sections

COVERAGE SUMMARY:
--------------------------------------------------------------------------------
Language          Complete    Missing     Coverage
--------------------------------------------------------------------------------
cs                    20          0       100.0% ✓
da                    20          0       100.0% ✓
de                    20          0       100.0% ✓
...
--------------------------------------------------------------------------------

STATISTICS:
  Total translations: 22
  Complete (100%): 22
  Partial: 0
  Average coverage: 100.0%
```

## Using the Data

### Identifying Translation Work

1. Run the tool for the latest version:
   ```bash
   ruby translation_coverage.rb --version 1.1.0
   ```

2. Look for languages with coverage < 100%

3. Use `--details` to see exactly which sections are missing:
   ```bash
   ruby translation_coverage.rb --version 1.1.0 --details
   ```

### Tracking Progress

Export to CSV and track over time:

```bash
ruby translation_coverage.rb --format csv > coverage_$(date +%Y%m%d).csv
```

### Cross-version Comparison

Check all versions to see which languages need updates:

```bash
ruby translation_coverage.rb --language fr
```

This shows French translation status across all versions, helping identify if a language needs updates when new sections are added.

## Command-Line Options

| Option | Short | Description |
|--------|-------|-------------|
| `--version VERSION` | `-v` | Filter by specific version (2.0.0, 1.1.0, 1.0.0, or 0.3.0) |
| `--language LANG` | `-l` | Filter by specific language code (e.g., es-ES, fr, de) |
| `--format FORMAT` | `-f` | Output format: text (default), json, or csv |
| `--migration` | `-m` | Show 2.0 migration workload (add / revise / carry per language) |
| `--details` | `-d` | Show detailed section-by-section breakdown |
| `--help` | `-h` | Show help message |

## Requirements

- Ruby (any version with standard library)
- No external gems required

## Technical Details

The tool works by:

1. **Scanning** the `source/` directory for all language/version combinations
2. **Extracting** section identifiers from HAML files:
   - For 1.0.0+: Extracts heading IDs from `%h3#section-id` and `%h4#section-id`
   - For 0.3.0: Extracts markdown headings from `:markdown` blocks
3. **Comparing** each language's sections against the English baseline
4. **Calculating** coverage percentages and identifying missing sections
5. **Reporting** results in the requested format

## Contributing

If you find issues or have suggestions for improving this tool, please open an issue or pull request.
