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

## Dashboard: a static visual overview

For a graphical view of the same data — a language × version coverage heatmap,
per-language progress bars toward the newest English version, and the list of
missing sections — generate the dashboard:

```bash
bin/rake translations:dashboard    # or: ruby translation_coverage.rb --dashboard
```

This writes [`translation-dashboard.html`](translation-dashboard.html), a
single **self-contained** file: the data is embedded as JSON and there are no
external assets, so it opens directly in any browser via `file://` — no
backend, no server, no build step. Re-run the task whenever translations
change to refresh it. The file is committed, so the latest snapshot is one
double-click away after cloning.

The same dashboard is **hosted on the site** at
[keepachangelog.com/translations/progress](https://keepachangelog.com/translations/progress/):
`source/translations/progress.html.erb` embeds the analyzer's output at build
time, so every build/deploy refreshes it automatically. A simpler
visitor-facing overview of the available translations — which languages
exist, which are up to date, and which need help — is built the same way at
[keepachangelog.com/translations](https://keepachangelog.com/translations/)
from `source/translations/index.html.erb`.

The page adapts to light/dark color schemes, and every value is also readable
as plain text (the heatmap is a real table with the percentage in each cell),
so nothing depends on color alone. Pass a path to write elsewhere:
`ruby translation_coverage.rb --dashboard build/dashboard.html`.

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

## Consistency Mode: auditing translations against the English change pattern

Migration mode asks *"what work does the next version create?"* Consistency mode
asks a different question about versions that already exist: *"did each
translation change in step with English, or did inconsistencies creep in?"*

Between two reference English versions (e.g. `1.0.0` → `1.1.0`) we know exactly
which sections were added, reworded, etc. A translation that has **both** of those
versions should mirror that pattern. Where it doesn't, the tool flags it:

```bash
ruby translation_coverage.rb --consistency
```

- **stale** — English reworded a section, but the translation's text is identical
  across its own two versions: the update was never propagated.
- **drift** — the translation changed a section English left unchanged. Split into
  **major** (similarity `< 0.9`, likely a wholesale re-translation) and **minor**
  (a word or two). Each drift carries a character-bigram similarity score
  (language-agnostic, works for CJK and Latin alike).
- **miss** — English added a section the translation never added.
- **kept** — English removed a section the translation still carries.

```
TRANSLATION CONSISTENCY  (1.0.0 → 1.1.0)
English delta: confusing-dates=reworded, inconsistent-changes=added

Language         Stale  Drift maj/min   Miss   Kept
ko                   0           16/0      0      0   ← re-translated wholesale
de                   0            0/2      0      0   ← two minor word changes
fr                   0            0/0      0      0   ← changed only where English did
```

Use `--details` for the per-section drift list (sorted by similarity, most-changed
first), `--language LANG` to focus, or `--format json`.

> Drift is frequently *legitimate* — a translator polishing their wording, or a new
> maintainer redoing a translation. It isn't necessarily an error; it's a divergence
> worth reviewing. **stale**, **miss**, and **kept** are the higher-signal flags
> that a translation has fallen out of step. Comparisons need stable section IDs, so
> `0.3.0` (translated markdown headings) is excluded.

## Mistranslation QA: deterministic checks + external triage

The modes above audit *structure* and *change patterns*. Catching actual
**mistranslations** is split into two auditable layers — the tool never makes a
judgement call itself.

### Layer 1 — Deterministic lint (`--lint`)

Rule-based, fully explainable checks comparing each translated section to its
English source. Every flag is mechanical and exact (no model, reproducible):

```bash
ruby translation_coverage.rb --lint            # summary table
ruby translation_coverage.rb --lint --details  # every finding with its reason
```

- **untranslated** — section text is ~identical to English (≥ 0.95 similarity);
  non-Latin scripts score near zero against English, so this only fires on text
  genuinely left in English.
- **missing-term** — `[YANKED]` / `Unreleased` / `CHANGELOG` present in English
  but absent from the translation.
- **missing-lit** — a release date or semver version present in English is gone.
- **link-count** — the translation has a different number of links than English
  (a dropped or added link).

By policy, **localizing the canonical change types** (`Added`/`Changed`/…) into
each language is **allowed** and is *not* flagged by default. Projects that want
those headers kept verbatim everywhere can opt in:

```bash
ruby translation_coverage.rb --lint --strict-types   # adds a loc-type column
```

Output also as `--format json` / `--format csv`.

### Layer 2 — Semantic triage with an external model

For meaning errors that rule-based checks can't see, export aligned segments and
score them with a pinned, open-source model — *not* this assistant.

**One-time setup** (creates `tools/.venv`, installs pinned deps, downloads the
model). The model is **LaBSE**, pulled from Hugging Face
(`sentence-transformers/LaBSE`, ~1.8 GB) into your standard Hugging Face cache
(`~/.cache/huggingface`) — the conventional location, shared across projects, so
it downloads only once:

```bash
bin/rake translations:setup      # or: tools/setup.sh
```

To keep the model project-local instead of the shared cache, set `HF_HOME`:

```bash
HF_HOME="$PWD/tools/.models" tools/setup.sh
```

**Run the triage** (export segments → score with LaBSE, low similarity first):

```bash
bin/rake translations:qa         # the whole pipeline in one command
```

or step by step:

```bash
# JSONL is the default; `po` and `csv` also work (pofilter / Weblate / sheets).
ruby translation_coverage.rb --segments --format jsonl > segments.jsonl
tools/.venv/bin/python tools/labse_triage.py segments.jsonl --max-similarity 0.7
```

The run prints the exact model + library versions, and `tools/setup.sh` writes
`tools/requirements.lock.txt` (a `pip freeze`), so every run is reproducible.

**Relative vs absolute scoring.** LaBSE similarity has a strong per-section
baseline: short sections (a heading, a one-line answer) score low for *every*
language, so an absolute cutoff (`--max-similarity 0.7`) mostly surfaces hard
sections, not mistranslations. **`--relative`** (used by `translations:qa`)
instead ranks each translation by how far it falls *below its section's median
across all languages* — isolating genuine per-language divergences. In practice
this is the difference between a noisy list dominated by short sections and a
short list of real outliers (e.g. it pinpoints a `confusing-dates` translation
still using an old US-centric date example the English long since replaced —
a stale-meaning case the deterministic `--consistency` check cannot see).

```bash
python3 tools/labse_triage.py segments.jsonl --relative              # default cutoff -0.08
python3 tools/labse_triage.py segments.jsonl --max-similarity 0.6    # absolute, if preferred
```

The `med` and `d` columns show each section's cross-language median and the
segment's delta from it, so you can always see whether a low score is the section
being hard or the translation being an outlier.

`segments.jsonl` can equally be fed to other auditable tools — `pofilter`
(Translate Toolkit), LanguageTool, Weblate's checks, or COMET-Kiwi. The export is
deterministic (aligned by stable section ID), so whichever tool you choose, the
inputs are reproducible.

> Both layers **flag candidates**; a human makes the final call. Layer 1 is
> rule-explainable; Layer 2 is reproducible via a pinned model but not
> rule-explainable. Neither relies on a black-box judgement from an LLM.

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
| `--consistency` | `-c` | Audit translation change patterns vs English (stale / drift / miss / kept) |
| `--lint` | | Deterministic QA: untranslated text, dropped terms/dates/versions, link mismatches |
| `--strict-types` | | With `--lint`, also flag change types (`Added`/…) that were localized |
| `--segments` | | Export aligned en↔translation segments (`--format jsonl`/`csv`/`po`) for external QA |
| `--dashboard [PATH]` | | Write the self-contained HTML dashboard (default: `translation-dashboard.html`) |
| `--details` | `-d` | Show detailed section-by-section breakdown |
| `--help` | `-h` | Show help message |

## Requirements

- Ruby (any version with standard library)
- No external gems required

## Technical Details

The tool works by:

1. **Scanning** the `source/` directory for all language/version combinations
2. **Extracting** section identifiers from each version's page (HAML for
   0.3.0–1.1.0, markdown from 2.0.0 on):
   - For 1.0.0 and 1.1.0: Extracts heading IDs from `%h3#section-id` and `%h4#section-id`
   - For 2.0.0+: Extracts explicit kramdown anchors (`## Heading {#section-id}`)
     from `index.html.md`, skipping fenced code blocks
   - For 0.3.0: Extracts markdown headings from `:markdown` blocks
3. **Comparing** each language's sections against the English baseline
4. **Calculating** coverage percentages and identifying missing sections
5. **Reporting** results in the requested format

## Contributing

If you find issues or have suggestions for improving this tool, please open an issue or pull request.
