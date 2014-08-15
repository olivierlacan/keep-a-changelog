# Keep a CHANGELOG

## Don’t let your friends dump git logs into CHANGELOGs&trade;

### What’s a CHANGELOG?
A CHANGELOG is a file which contains a curated chronologically ordered
list of notable changes for each version of an open source project.

[![Changelog Example](assets/images/changelog_example.png)][CHANGELOG]

### What’s the point of a CHANGELOG?
To make it easier for users and contributors to see precisely what
notable changes have been made between each release (or version) of the project.

### Why should I care?
Well, because software tools are for people. If you don’t care, why are
you contributing to open source? There must be a kernel (ha) of care
somewhere in that lovely little brain of yours.

I [talked with Adam Stacoviak and Jerod Santo on The Changelog](http://5by5.tv/changelog/127)
(fitting, right?) podcast about why open source maintainers and
contributors should care, and the motivations behind this project. If
you can spare the time (1:06), it’s a good listen.

### What makes up a good CHANGELOG?
I’m glad you asked.

- It’s made for humans, not machines, so legibility is crucial.
- One sub-section per versions.
- Versions should come with a release date in a sensible format: YYYY-MM-DD.
- Changes should be grouped to describe their impact on the project:
  - `Added` for new features.
  - `Deprecated` for once stable features removed in upcoming releases.
  - `Removed` for deprecated features removed in this release.
  - `Fixed` for any bug fixes.
  - `Security` to invite users to upgrade in case of vulnerabilities.
- Each section should be easily linked to — hence Markdown over plain text.
- Write release dates in an international, sensible, and
language-independent format: `2012-06-02` for `June 2nd, 2012`.
- Order the releases reverse chronologically (latest at the top).

It’s also good to mention whether the project
follows [Semantic Versioning][semver].

### What makes unicorns cry?
Alright, let’s get into it:

- Dumping a diff of commit logs. Just don’t do that, you’re helping nobody.
- Not emphasizing deprecations: when people upgrade from one version to
another it should be painfully clear when something will break.
- Dates in regionally-specific formats. Americans put the month first
("06-02-2012" for June 2nd, 2012, which makes *no* sense), while Brits
use a robotic-looking "2 June 2012", yet pronounce it "June 2nd, 2012".

There’s more. Help me collect those unicorn tears by
[opening an issue](https://github.com/olivierlacan/keep-a-changelog/issues/new)
or a pull request.

### Is there a standard CHANGELOG format?
Sadly, no, but this is something I want to change. This project
[contains what I hope will become the standard CHANGELOG file][CHANGELOG]
for all open source projects, so take a look at it and please suggest improvements.

### What should the CHANGELOG file be named?
Well, if you can’t tell from the example above, `CHANGELOG.md` is the
best convention so far.

Some projects also use `HISTORY.txt`, `HISTORY.md`, `History.md`, `NEWS.txt`,
`NEWS.md`, `News.txt`, `RELEASES.txt`, `RELEASE.md`, `releases.md`, etc.
It’s a mess, that only makes it harder for people to find it.

### Why can’t people just use a git log diff?
Because log diffs are full of noise. Can we really expect every single
commit in an open source project to be meaningful and self-explanatory?
That seems like a pipe dream.

### Can CHANGELOG files be automatically parsed?
It’s hard because people follow wildly different formats and file names.
[Vandamme](https://github.com/tech-angels/vandamme/) is a Ruby gem
created by the [Gemnasium](http://gemnasium.com) team and which parses
many (but not all) open source project CHANGELOGs.

### Why do you keep writing CHANGELOG in all caps?
You’re right, that is a bit shouty. Maybe it’s because of the de facto
convention that files pertaining to an open source project should be in
all caps, for instance: [`README`](README.md), [`LICENSE`](LICENSE),
[`CONTRIBUTING`](CONTRIBUTING.md).

It denotes that these files are metadata for the project, similarly to
[open source project badges](http://shields.io/) they draw attention to
themselves as information people should be aware of if they mean to use
the project or contribute to it.

### How can I contribute?
This document is not the **truth**, it’s my carefully considered
opinion with the information and examples I was able to gather. Although
I provide an actual [CHANGELOG][] on [the GitHub repo](https://github.com/olivierlacan/keep-a-changelog),
I have purposefully not created a proper *release* or clear list of rules
to follow like [SemVer.org][semver] does for instance. This is
because I want our community to reach a consensus. I believe the discussion
is as important as the end result. So please [**pitch in**](https://github.com/olivierlacan/keep-a-changelog/issues).


[CHANGELOG]: ./CHANGELOG.md
[semver]: http://semver.org