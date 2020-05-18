# <img src="https://d3vv6lp55qjaqc.cloudfront.net/items/1L1w0v431V0d1K410f3Y/keepAChangelog-logo-dark.svg" height=150 alt="Keep a Changelog" />

[![Keep a Changelog v1.1.0 badge][changelog-badge]][changelog] [![Version 1.1.0 Badge][version-badge]][changelog] [![MIT License Badge][license-badge]][license]

Don’t let your friends dump git logs into changelogs™

This repository generates https://keepachangelog.com/.

## Development

### Dependencies

- Ruby ([see version][ruby-version], [rbenv][rbenv] recommended)
- Bundler (`gem install bundler`)

### Installation

- `git clone https://github.com/olivierlacan/keep-a-changelog.git`
- `cd keep-a-changelog`
- `bundle install`
- `bundle exec middleman` starts the local development server at http://localhost:4567

### Deployment

- `bundle exec rake publish` builds and pushes to the `gh-pages` branch

### Translations

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

## Contribute

Please do contribute! Issues and pull requests are welcome.

Thank you for your help improving software one changelog at a time!

[changelog]: ./CHANGELOG.md
[changelog-badge]: https://img.shields.io/badge/changelog-Keep%20a%20Changelog%20v1.1.0-%23E05735
[license]: ./LICENSE
[rbenv]: https://github.com/rbenv/rbenv
[ruby-version]: .ruby-version
[source]: source/
[pull-request]: https://help.github.com/articles/creating-a-pull-request/
[fork]: https://help.github.com/articles/fork-a-repo/
[version-badge]: https://img.shields.io/badge/version-1.1.0-blue.svg
[license-badge]: https://img.shields.io/badge/license-MIT-blue.svg
