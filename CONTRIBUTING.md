# Contributing to Keep a Changelog

Please do contribute! Issues and pull requests are welcome. This file is the
single home for contributor guidance — how to set up the project, work on it,
and submit changes. For the principles behind how the project is built, see
[AGENTS.md](AGENTS.md).

## Development

### Dependencies

- Ruby ([see version][ruby-version], [rbenv][rbenv] recommended)
- Bundler (`gem install bundler`)

### Installation

- `git clone https://github.com/olivierlacan/keep-a-changelog.git`
- `cd keep-a-changelog`
- `bundle install`

### Common tasks

- `bin/rake serve` starts a local development server at http://localhost:4567
  which will reload with any local file changes
- `bin/rake build` runs middleman build with `--verbose` flag so build errors are
  logged for easier debugging
- `bin/rake test` runs the Minitest suite (also the default task)
- `bundle exec standardrb` checks Ruby style ([Standard][standard])

### Visual regression tests

Cross-browser screenshot tests (Playwright, dev-only; not shipped with the
site) guard against unintended visual changes:

- `bin/rake snapshots:baseline` builds the site and records baseline screenshots
- `bin/rake snapshots:check` rebuilds and diffs against the baseline
- `bin/rake snapshots:sweep:baseline` / `snapshots:sweep:check` do the same for
  the breakpoint sweep alone, which is much faster while iterating on a layout
  change

Two kinds of coverage run together: full-page shots of representative pages
on all three browser engines (`test/visual/visual.spec.js`), and a
breakpoint sweep (`test/visual/responsive.spec.js`) that screenshots
individual components — header, hero, footer, and so on — at one width per
layout regime, so a change checked only at desktop width can't silently
break the phone or tablet layouts. If you add or move a CSS breakpoint,
update the width list in the sweep to keep one probe inside each regime.

### Deployment

- `bin/rake clean` can clean a corrupted `build/` directory in
  case `publish` failed
- `bin/rake deploy` cleans, builds and pushes to the `gh-pages` branch on GitHub so
  the site is deployed to keepachangelog.com

## Translations

To see where help is needed at a glance, visit
[keepachangelog.com/translations](https://keepachangelog.com/translations/) —
a simple overview of every available translation — or the detailed
[translation-progress dashboard](https://keepachangelog.com/translations/progress/)
showing coverage across every language and version. Both pages are rebuilt
from the source tree on every deploy.

Create a new directory in [`source/`][source] named after the ISO 639-1 code
for the language you wish to translate Keep a Changelog to. For example,
assuming you want to translate to French Canadian:

- create the `source/fr-CA` directory.
- duplicate the `source/en/1.0.0/index.html.haml` file in `source/fr-CA`.
- edit `source/fr-CA/1.0.0/index.html.haml` until your translation is ready.
- commit your changes to your own [fork][fork]
- submit a [Pull Request][pull-request] with your changes

It may take some time to review your submitted Pull Request. Try to involve a
few native speakers of the language you're translating to in the Pull Request
comments. They'll help review your translation for simple mistakes and give us
a better idea of whether your translation is accurate.

Translations are human work. This project does not use LLMs to replace
translators, and a translation needs your judgment about what reads naturally
in your language and culture — not just what matches the English words. The
automated checks below only help find gaps and inconsistencies; they don't
write or approve translations. [AGENTS.md](AGENTS.md) explains how the project
uses LLMs and where it draws the line.

### Translation checks

- `ruby translation_coverage.rb` reports how complete each translation is
  (see [TRANSLATION_COVERAGE.md](TRANSLATION_COVERAGE.md))
- `bin/rake translations:dashboard` regenerates the static coverage dashboard
  ([`translation-dashboard.html`](translation-dashboard.html), also hosted at
  [/translations/progress](https://keepachangelog.com/translations/progress/))
- `bin/rake translations:lint` runs a deterministic, rule-based translation lint
- `bin/rake translations:qa` scores translated segments semantically
  (one-time setup: `bin/rake translations:setup`)

## Pull requests

These apply to humans and AI agents alike:

- Always include screenshots of visual changes when possible. Build the site
  (`bin/rake build`), capture the affected pages in both light and dark modes,
  and embed the images in the PR description.
- Be succinct in PR descriptions. Link to code, docs, issues, or live pages
  instead of restating their content.
- Don't format plain text weird: write normal paragraphs with no artificial
  line returns (hard wraps) and let text wrap naturally.
- Use GitHub-flavored Markdown properly — headings, lists, tables, and code
  fences where they help — so the description renders well.

Thank you for your help improving software one changelog at a time!

[rbenv]: https://github.com/rbenv/rbenv
[ruby-version]: .ruby-version
[source]: source/
[standard]: https://github.com/standardrb/standard
[pull-request]: https://help.github.com/articles/creating-a-pull-request/
[fork]: https://help.github.com/articles/fork-a-repo/
