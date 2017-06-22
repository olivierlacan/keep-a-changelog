# <img src="https://d3vv6lp55qjaqc.cloudfront.net/items/1L1w0v431V0d1K410f3Y/keepAChangelog-logo-dark.svg" height=150 alt="Keep a Changelog" />

[![version][version-badge]][CHANGELOG] [![license][license-badge]][LICENSE]

Don’t let your friends dump git logs into changelogs™

### What’s a changelog?
A changelog is a file which contains a curated, chronologically ordered
list of notable changes for each version of a project.
=======
This repository generates http://keepachangelog.com/.

## Development
### Dependencies

### What’s the point of a changelog?
To make it easier for users and contributors to see precisely what
notable changes have been made between each release (or version) of the project.
=======
- Ruby ([see version][ruby-version], [rbenv][rbenv] recommended)
- Bundler (`gem install bundler`)

### Installation

- `git clone https://github.com/olivierlacan/keep-a-changelog.git`
- `cd keep-a-changelog`
- `bundle install`
- `bundle exec middleman` starts the local development server at http://localhost:4567

### What makes a good changelog?
I’m glad you asked.

A good changelog sticks to these principles:
=======
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

This serves two purposes:

- People can see what changes they might expect in upcoming releases
- At release time, you just have to change `"Unreleased"` to the version number
  and add a new `"Unreleased"` header at the top.

### What makes unicorns cry?
Alright…let’s get into it.

- **Dumping a diff of commit logs.** Just don’t do that, you’re helping nobody.
- **Not emphasizing deprecations.** When people upgrade from one version to
  another, it should be painfully clear when something will break.
- **Dates in region-specific formats.** In the U.S., people put the month first
  ("06-02-2012" for June 2nd, 2012, which makes *no* sense), while many people
  in the rest of the world write a robotic-looking "2 June 2012", yet pronounce
  it differently. "2012-06-02" works logically from largest to smallest, doesn't
  overlap in ambiguous ways with other date formats, and is an
  [ISO standard](http://www.iso.org/iso/home/standards/iso8601.htm). Thus, it
  is the recommended date format for changelogs.

There’s more. Help me collect those unicorn tears by
[opening an issue][issues]
or a pull request.

### Is there a standard changelog format?
Sadly, no. Calm down. I know you're furiously rushing to find that link
to the GNU changelog style guide, or the two-paragraph GNU NEWS file
"guideline". The GNU style guide is a nice start but it is sadly naive.
There's nothing wrong with being naive but when people need
guidance it's rarely very helpful. Especially when there are many
situations and edge cases to deal with.

This project [contains what I hope will become a better CHANGELOG file convention][CHANGELOG].
I don't think the status quo is good enough, and I think that as a community we
can come up with better conventions if we try to extract good practices from
real software projects. Please take a look around and remember that
[discussions and suggestions for improvements are welcome][issues]!

### What should the changelog file be named?
Well, if you can’t tell from the example above, `CHANGELOG.md` is the
best convention so far.

Some projects also use `HISTORY.txt`, `HISTORY.md`, `History.md`, `NEWS.txt`,
`NEWS.md`, `News.txt`, `RELEASES.txt`, `RELEASE.md`, `releases.md`, etc.

It’s a mess. All these names only makes it harder for people to find it.

### Why can’t people just use a `git log` diff?
Because log diffs are full of noise — by nature. They could not make a suitable
changelog even in a hypothetical project run by perfect humans who never make
typos, never forget to commit new files, never miss any part of a refactoring.
The purpose of a commit is to document one atomic step in the process by which
the code evolves from one state to another. The purpose of a changelog is to
document the noteworthy differences between these states.

As is the difference between good comments and the code itself,
so is the difference between a changelog and the commit log:
one describes the *why*, the other the how.

### Can changelogs be automatically parsed?
It’s difficult, because people follow wildly different formats and file names.

[Vandamme][vandamme] is a Ruby gem
created by the [Gemnasium][gemnasium] team and which parses
many (but not all) open source project changelogs.

### Why do you alternate between spelling it "CHANGELOG" and "changelog"?
"CHANGELOG" is the name of the file itself. It's a bit shouty but it's a
historical convention followed by many open source projects. Other
examples of similar files include [`README`](README.md), [`LICENSE`](LICENSE),
and [`CONTRIBUTING`](CONTRIBUTING.md).

The uppercase naming (which in old operating systems made these files stick
to the top) is used to draw attention to them. Since they're important
metadata about the project, they could be useful to anyone intending to use
or contribute to it, much like [open source project badges][shields].

When I refer to a "changelog", I'm talking about the function of this
file: to log changes.

### What about yanked releases?
Yanked releases are versions that had to be pulled because of a serious
bug or security issue. Often these versions don't even appear in change
logs. They should. This is how you should display them:

`## 0.0.5 - 2014-12-13 [YANKED]`

The `[YANKED]` tag is loud for a reason. It's important for people to
notice it. Since it's surrounded by brackets it's also easier to parse
programmatically.

### Should you ever rewrite a changelog?
Sure. There are always good reasons to improve a changelog. I regularly open
pull requests to add missing releases to open source projects with unmaintained
changelogs.

It's also possible you may discover that you forgot to address a breaking change
in the notes for a version. It's obviously important for you to update your
changelog in this case.

### How can I contribute?
This document is not the **truth**; it’s my carefully considered
opinion, along with information and examples I gathered.
Although I provide an actual [CHANGELOG][] on [the GitHub repo][gh],
I have purposefully not created a proper *release* or clear list of rules
to follow (as [SemVer.org][semver] does, for instance).

This is because I want our community to reach a consensus. I believe the
discussion is as important as the end result.

So please [**pitch in**][gh].
=======
Thank you for your help improving software one changelog at a time!

[CHANGELOG]: ./CHANGELOG.md
[LICENSE]: ./LICENSE
[rbenv]: https://github.com/rbenv/rbenv
[ruby-version]: .ruby-version
[source]: source/
[pull-request]: https://help.github.com/articles/creating-a-pull-request/
[fork]: https://help.github.com/articles/fork-a-repo/
[version-badge]: https://img.shields.io/badge/version-1.0.0-blue.svg
[license-badge]: https://img.shields.io/badge/license-MIT-blue.svg
