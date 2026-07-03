# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/2.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Older spec pages no longer display an example changelog written to newer
  conventions than the page describes: each page's example is now pinned to
  its own version's last release, derived at build time from this file.

## [2.0.0] - 2026-06-07

2.0.0 is the first major revision of Keep a Changelog. It breaks the guidance,
not the format: the six change types, `YYYY-MM-DD` dates, and the `Unreleased`
and `[YANKED]` markers are all unchanged, so your existing changelog stays valid.
What breaks is the surface around it. The page is restructured so some older
section links no longer resolve, the recommended guidance has shifted, and
existing translations are out of date until they catch up. The breaking changes
are marked below.

### Added

- New guidance answering long-standing community questions:
  - Format: the `# Changelog` header preamble; marking breaking changes and
    where upgrade steps belong; choosing between Changed, Fixed, and Security;
    leading a Security entry with its CVE; why the six change types don't grow.
  - Versioning: schemes beyond SemVer, and linking each version to a `compare`
    diff with reference links.
  - Changelogs vs. release notes: how to derive one from the other without
    duplicate work, and why a host's generated notes are vendor lock-in.
  - Automation: LLM-drafted changelogs with a brief for an `AGENTS.md`;
    Conventional Commits; CI/CD; linking issues and pull requests; crediting
    contributors.
  - Scale: very large changelogs and monorepos.
  - Optional per-release summaries, and a statement of what Keep a Changelog
    deliberately won't do.
- A redesigned, accessible site (WCAG 2.1 AA) with light and dark themes.

### Changed

- **Breaking:** Retired the tagline "Don't let your friends dump git logs into
  changelogs" for "Clearly document the evolution of your projects." Earlier
  versions keep the original.
- **Breaking:** Restructured the page from a flat FAQ into integrated guidance,
  in a plainer, less first-person voice. Some older section links no longer resolve.
- Reframed the "GitHub Releases" answer as "Is a changelog the same as release
  notes?", broadened beyond GitHub to any host.
- Set page titles and descriptions from frontmatter, and fixed OpenGraph metadata
  so shared links render correctly and language-appropriately.

### Removed

- Outdated specifics (the Vandamme gem reference and a GitHub-Releases
  discoverability note) in favor of more general guidance.
- **Breaking:** The FAQ scaffolding and most first-person framing, whose section
  anchors no longer resolve; the podcast note now lives in the References section.

## [1.1.2] - 2024-09-27

### Added

- v1.1 German translation.
- v1.1 Italian translation.
- v1.1 Simplified Chinese translation.
- v1.1 Persian translation.
- v1.1 Polish translation.
- v1.1 Slovenian translation.
- v1.1 Traditional Chinese translation.
- v1.1 Spanish translation.
- v1.1 Brazilian Portuguese translation.
- v1.1 Czech translation.
- v1.1 Romanian translation.
- v1.1 Swedish translation.
- v1.1 Ukrainian translation.
- v1.1 Korean translation.
- v1.1 Indonesian translation.

### Fixed

- Improve French translation.
- Improve Dutch translation.

## [1.1.1] - 2023-03-05

### Added

- v1.1 Arabic translation.
- v1.1 French translation.
- v1.1 Dutch translation.
- v1.1 Russian translation.
- v1.1 Japanese translation.
- v1.1 Norwegian Bokmål translation.
- v1.1 "Inconsistent Changes" Turkish translation.
- Default to most recent versions available for each languages.
- Display count of available translations (26 to date!).
- Centralize all links into `/data/links.json` so they can be updated easily.

### Fixed

- Improve French translation.
- Improve id-ID translation.
- Improve Persian translation.
- Improve Russian translation.
- Improve Swedish title.
- Improve zh-CN translation.
- Improve French translation.
- Improve zh-TW translation.
- Improve Spanish (es-ES) transltion.
- Foldout menu in Dutch translation.
- Missing periods at the end of each change.
- Fix missing logo in 1.1 pages.
- Display notice when translation isn't for most recent version.
- Various broken links, page versions, and indentations.

### Changed

- Upgrade dependencies: Ruby 3.2.1, Middleman, etc.

### Removed

- Unused normalize.css file.
- Identical links assigned in each translation file.
- Duplicate index file for the english version.

## [1.1.0] - 2019-02-15

### Added

- Danish translation.
- Georgian translation from.
- Changelog inconsistency section in Bad Practices.

### Fixed

- Italian translation.
- Indonesian translation.

## [1.0.0] - 2017-06-20

### Added

- New visual identity by [@tylerfortune8].
- Version navigation.
- Links to latest released version in previous versions.
- "Why keep a changelog?" section.
- "Who needs a changelog?" section.
- "How do I make a changelog?" section.
- "Frequently Asked Questions" section.
- New "Guiding Principles" sub-section to "How do I make a changelog?".
- Simplified and Traditional Chinese translations from [@tianshuo].
- German translation from [@mpbzh] & [@Art4].
- Italian translation from [@azkidenz].
- Swedish translation from [@magol].
- Turkish translation from [@emreerkan].
- French translation from [@zapashcanon].
- Brazilian Portuguese translation from [@Webysther].
- Polish translation from [@amielucha] & [@m-aciek].
- Russian translation from [@aishek].
- Czech translation from [@h4vry].
- Slovak translation from [@jkostolansky].
- Korean translation from [@pierceh89].
- Croatian translation from [@porx].
- Persian translation from [@Hameds].
- Ukrainian translation from [@osadchyi-s].

### Changed

- Start using "changelog" over "change log" since it's the common usage.
- Start versioning based on the current English version at 0.3.0 to help
  translation authors keep things up-to-date.
- Rewrite "What makes unicorns cry?" section.
- Rewrite "Ignoring Deprecations" sub-section to clarify the ideal
  scenario.
- Improve "Commit log diffs" sub-section to further argument against
  them.
- Merge "Why can’t people just use a git log diff?" with "Commit log
  diffs".
- Fix typos in Simplified Chinese and Traditional Chinese translations.
- Fix typos in Brazilian Portuguese translation.
- Fix typos in Turkish translation.
- Fix typos in Czech translation.
- Fix typos in Swedish translation.
- Improve phrasing in French translation.
- Fix phrasing and spelling in German translation.

### Removed

- Section about "changelog" vs "CHANGELOG".

## [0.3.0] - 2015-12-03

### Added

- RU translation from [@aishek].
- pt-BR translation from [@tallesl].
- es-ES translation from [@ZeliosAriex].

## [0.2.0] - 2015-10-06

### Changed

- Remove exclusionary mentions of "open source" since this project can
  benefit both "open" and "closed" source projects equally.

## [0.1.0] - 2015-10-06

### Added

- Answer "Should you ever rewrite a change log?".

### Changed

- Improve argument against commit logs.
- Start following [SemVer] properly.

## [0.0.8] - 2015-02-17

### Changed

- Update year to match in every README example.
- Reluctantly stop making fun of Brits only, since most of the world
  writes dates in a strange way.

### Fixed

- Fix typos in recent README changes.
- Update outdated unreleased diff link.

## [0.0.7] - 2015-02-16

### Added

- Link, and make it obvious that date format is ISO 8601.

### Changed

- Clarified the section on "Is there a standard change log format?".

### Fixed

- Fix Markdown links to tag comparison URL with footnote-style links.

## [0.0.6] - 2014-12-12

### Added

- README section on "yanked" releases.

## [0.0.5] - 2014-08-09

### Added

- Markdown links to version tags on release headings.
- Unreleased section to gather unreleased changes and encourage note
  keeping prior to releases.

## [0.0.4] - 2014-08-09

### Added

- Better explanation of the difference between the file ("CHANGELOG")
  and its function "the change log".

### Changed

- Refer to a "change log" instead of a "CHANGELOG" throughout the site
  to differentiate between the file and the purpose of the file — the
  logging of changes.

### Removed

- Remove empty sections from CHANGELOG, they occupy too much space and
  create too much noise in the file. People will have to assume that the
  missing sections were intentionally left out because they contained no
  notable changes.

## [0.0.3] - 2014-08-09

### Added

- "Why should I care?" section mentioning The Changelog podcast.

## [0.0.2] - 2014-07-10

### Added

- Explanation of the recommended reverse chronological release ordering.

## [0.0.1] - 2014-05-31

### Added

- This CHANGELOG file to hopefully serve as an evolving example of a
  standardized open source project CHANGELOG.
- CNAME file to enable GitHub Pages custom domain.
- README now contains answers to common questions about CHANGELOGs.
- Good examples and basic guidelines, including proper date formatting.
- Counter-examples: "What makes unicorns cry?".

[unreleased]: https://github.com/olivierlacan/keep-a-changelog/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/olivierlacan/keep-a-changelog/compare/v1.1.2...v2.0.0
[1.1.2]: https://github.com/olivierlacan/keep-a-changelog/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/olivierlacan/keep-a-changelog/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/olivierlacan/keep-a-changelog/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.3.0...v1.0.0
[0.3.0]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.0.8...v0.1.0
[0.0.8]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.0.7...v0.0.8
[0.0.7]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.0.6...v0.0.7
[0.0.6]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.0.5...v0.0.6
[0.0.5]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.0.4...v0.0.5
[0.0.4]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.0.3...v0.0.4
[0.0.3]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/olivierlacan/keep-a-changelog/releases/tag/v0.0.1
[SemVer]: https://semver.org
[@tylerfortune8]: https://github.com/tylerfortune8
[@tianshuo]: https://github.com/tianshuo
[@mpbzh]: https://github.com/mpbzh
[@Art4]: https://github.com/Art4
[@azkidenz]: https://github.com/azkidenz
[@magol]: https://github.com/magol
[@emreerkan]: https://github.com/emreerkan
[@zapashcanon]: https://github.com/zapashcanon
[@Webysther]: https://github.com/Webysther
[@amielucha]: https://github.com/amielucha
[@m-aciek]: https://github.com/m-aciek
[@aishek]: https://github.com/aishek
[@h4vry]: https://github.com/h4vry
[@jkostolansky]: https://github.com/jkostolansky
[@pierceh89]: https://github.com/pierceh89
[@porx]: https://github.com/porx
[@Hameds]: https://github.com/Hameds
[@osadchyi-s]: https://github.com/osadchyi-s
[@tallesl]: https://github.com/tallesl
[@ZeliosAriex]: https://github.com/ZeliosAriex
