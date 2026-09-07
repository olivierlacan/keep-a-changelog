---
title: Keep a Changelog
description: Clearly document the evolution of your projects.
language: en
version: 2.0.0
---

## Changelog basics {#basics}

<div class="intro-grid" markdown="1">

<section class="intro-card" markdown="1">
### What is it? {#what}

A changelog is a curated, chronologically ordered list of the notable changes for each version of a project.

</section>

<section class="intro-card" markdown="1">
### Why keep one? {#why}

To make it easy for users and contributors to see the notable changes between each version.

</section>

<section class="intro-card" markdown="1">
### Who needs this? {#who}

People do. Anyone who uses or builds software wants to know what changed, and why.

</section>

</div>

## How do I keep a good changelog? {#how}

### Guiding principles {#principles}

- Changelogs are _for humans_, not machines.
- Every version should have an entry.
- Group changes of the same type.
- Make versions and sections linkable.
- List the latest version first.
- Show the release date of each version.
- Note which [versioning scheme][versioning-schemes] you use.
- Write plainly. Many of your readers are not native speakers, so favor clear, concise wording.

### Types of changes {#types}

- `Security` for vulnerabilities.
- `Removed` for now removed features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Fixed` for bug fixes.
- `Added` for new features.

We list the types in order of urgency, because readers skim a changelog to find what affects them. Lead with new features and they may miss a security fix or a removal. What a reader must act on goes above what is only good to know.

Prefer a different order? Fine, but keep it consistent across releases so readers know where to look. Leave out empty sections. Within a section, put the entries readers care about most first.

Three of the six are easy to confuse:

- `Fixed`: the behavior was wrong, and is now correct. A crash on empty input that no longer crashes is `Fixed`.
- `Changed`: the behavior worked as intended, and now works differently. A default timeout going from 30 to 60 seconds is `Changed`, even if users asked for it.
- `Security`: the change closes a vulnerability. It could fit under `Fixed` or `Changed`, but readers need to find it fast, and some of those readers are tools, so it gets its own type.

When a `Security` entry has a CVE identifier, lead with it so readers and security tools can match the entry to the advisory:

```
- CVE-2024-12345: out-of-bounds read when parsing malformed input.
```

A Security entry is a short, human-readable summary, not the full advisory. Keep it brief and link to the advisory (a CVE record, a security database entry, or your own security page) where readers and tools can find the affected versions, severity, and fix.

Some projects also have formal ways they must disclose vulnerabilities (a security advisory database, or rules for certain products). A changelog does not replace those; publish the advisory where it belongs and point to it.

<aside markdown="1">
There are only six types on purpose. What kind of change it is goes in the type; why it matters goes in the wording of the entry, not in a new type.
</aside>

An entry like "Rewrote JSON parser; 3x faster on large files" belongs under `Changed`, not `Performance`. You can add a type if you truly need one. We have yet to see a case that did: `Improved` and `New` are `Changed` and `Added` with different labels, and `Internal` or `Housekeeping` changes rarely deserve an entry at all. Six types mean every changelog reads the same way, and parses the same way.

**Dependencies** are not a type of change. A dependency update can be harmless, a fix, or breaking. If it matters to your users, describe its effect under the right type. If it does not, leave it out.

**Known issues** are discovered, not changed. Note them on the affected version or in your issue tracker. When one is fixed, it goes under `Fixed`.

### Breaking changes {#breaking}

Mark breaking changes clearly. The version number already signals them (under [Semantic Versioning][semver], a major release is where they belong), but the number is easy to miss, so highlight them in the entry. Breaking changes usually go under `Changed` or `Removed`. Add a short `**Breaking:**` marker so they stand out, and keep them with the type of change they are:

```
- **Breaking:** parse() now returns a result object instead of raising.
```

Say what breaks. The word means little until readers know which interface you keep stable: a command line, a library API, a network protocol, a file format, or a configuration schema. State which one your versioning scheme covers.

A short upgrade note can sit in the entry itself, such as "rename the `color` option to `theme`." When the steps are substantial, link to them (a migration guide or the release notes) rather than spelling them out here. A long procedure buries what changed and turns a scannable record into a how-to: a different kind of document, for a narrower audience. Keep the `**Breaking:**` marker on the entry itself, within its type, rather than collecting breaks into a separate section, so anyone scanning `Changed` or `Removed` sees them in place.

### Naming the part it touches {#areas}

In a project with distinct parts or features, an entry can name the part it touches:

```
- CLI: `brcat` alias for decoding streams.
- Parser: recover from a missing final chunk instead of raising.
```

Similarly to change types they can group entries by area of focus. They shouldn't be used at the same heading level as types but there may be situations where multiple changes relate to the same focus area. In that case nesting under a level-4 heading can work:

```
### Added
#### CLI
- New `--verbose` flag for detailed output
- New `--dry-run` flag that won't execute commands
```

Try to limit those areas and to be consistent. A name is worth adding when it tells readers something the entry doesn't; skip it when the change is plainly about one thing. Like the `**Breaking:**` marker, this is an option, not a requirement.

An added benefit follows from writing these plainly. Because the names are consistent, a short script can group the changelog by area. As with release notes, the changelog remains the source, but in this case focused on the history of one area.

### Structuring a release {#releasing}

Keep an `Unreleased` section at the top to collect upcoming changes. It shows readers what to expect, and at release time you move its contents into a new version. Starting on a project that has no changelog? Begin here, recording notable changes from now on. Reconstructing past releases from your version history is also worthwhile if you want a fuller record; either is fine.

A version starts with its number and date, for example `## [1.0.0] - 2017-07-17`. Use the `YYYY-MM-DD` format. It orders from the largest unit to the smallest, avoids the confusion of regional date formats, and is an [ISO standard][iso-8601].

The square brackets around `[1.0.0]` make it a Markdown reference link. Resolve it once at the bottom of the file, pointing each version to a comparison with the one before it:

```
[Unreleased]: https://github.com/your/project/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/your/project/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/your/project/releases/tag/v1.0.0
```

`[Unreleased]` compares the latest tag to `HEAD` (the current state of your code), so it always shows what has changed since the last release. The oldest version links to its tag, since there is nothing earlier to compare it with. Every version is then tied to its tag and links to the exact diff of what changed. Any host exposes tag and comparison URLs, so this works wherever your code lives, and the link stays out of the heading, so the changelog still reads cleanly.

When you release a version, rename `Unreleased` to the new version in both the heading and its link, then add a fresh, empty `Unreleased` section pointing at `HEAD`.

A version may open with a short summary before the typed sections: a sentence or two on the theme of the release or a notable change. This is optional. Use it when a release is worth introducing, and skip it otherwise.

You do not have to use Semantic Versioning. [Calendar versioning][calver], a plain number, or a date all work; note which scheme you use so readers can read your version numbers. Some projects release continuously and have no version numbers. A changelog still helps: keep dated entries under `Unreleased`.

### Curate, don't accumulate {#curation}

Keeping a changelog is partly an act of restraint. A changelog records _notable_ changes, which means some changes are not notable and do not belong in it. Deciding which is which takes judgment, and that judgment is human.

<aside markdown="1">
Making changes and communicating about changes are two different tasks. Curating a changelog does not mean sorting every commit into a type as you make it. That is tedious, and it is not the goal: write the changelog as a summary for your readers, not as a record of your commits.
</aside>

### What should the file be named? {#filename}

Name it `CHANGELOG.md`. Some projects use `HISTORY`, `NEWS`, or `RELEASES`. The name may feel unimportant, but why make it harder for your users to find what changed? A changelog does not need to list every change; version control already does that. It lists the notable ones.

### What goes at the top of the file? {#header}

Open with a `# Changelog` heading and a short, fixed preamble that says what the file is and which conventions it follows:

```
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/2.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
```

Stating the conventions you follow tells readers, and tools, what to expect. The first link declares the format; the second names your versioning scheme (Semantic Versioning here, but reference whichever you use). Pin the Keep a Changelog link to the version you follow, so it stays accurate as this page changes.

Adopting a newer version of this format does not mean rewriting your history. Leave past entries as they are, apply the new conventions from your next release onward, and update the version in the link to match. Noting the switch in that release helps readers, for example a short summary line saying the changelog now follows Keep a Changelog 2.0.0. A changelog spans years and more than one version of these conventions, and old entries stay valid, so there is no need to redo them.

### Is a changelog the same as release notes? {#release-notes}

No, although they draw from the same material. A changelog is the complete, ongoing record: every notable change, across every version, kept in one file in the repository and written plainly for anyone. Release notes are an announcement for a single release: a curated selection of its headline changes, often with upgrade steps and a marketing voice, published at release time. The changelog is the source; release notes are drawn from it and shaped for the announcement. Keep the changelog as the record, and write the release notes from it rather than maintaining two.

This does not have to mean doing the work twice. At release time, the version's section in the changelog is already the draft: copy it into the release, and expand it only if the announcement wants more. Because every version sits under a predictable `## [x.y.z]` heading, a small script can extract that section and create the release without anyone retyping it.

A host will offer to do this for you. Its release system attaches notes to a tag, notifies watchers, collects build files, and can even generate the notes from merged pull requests or commit messages. That is convenient, and we are not telling you to skip it. But the result lives in the host's database, not your repository. Those notes do not travel with the code, so if you move to another host, they do not come with you. Your changelog does, because it is a file in the repository.

You can treat a generated draft as a starting point, but keep `CHANGELOG.md` as the canonical record and generate host-specific release posts from it. That way you still get the host's reach (notifications, a visible page, attached downloads), and the full history stays in a file you control and can read offline.

## What makes a changelog worse? {#bad-practices}

### Commit log diffs {#log-diffs}

Do not paste a list of commits and call it a changelog. It is full of noise: merge commits, unclear messages, internal changes. A commit records a step in the source code. A changelog entry records a notable difference, often across several commits, written for the people who use the software.

> A "git log" is the list of commits in a [git][git] repository. We mention git because it is the most common [version control system][vcs], but this applies to any of them: a raw commit history is not a changelog.

### Ignoring deprecations {#ignoring-deprecations}

When someone upgrades, it should be impossible to miss what will break. Announce a deprecation before you act on it: mark it `Deprecated` in one release, and only `Removed` in a later one, so anyone upgrading meets the warning before the change. Say which version will remove it, so they can plan. If you do nothing else, always record deprecations, removals, and breaking changes.

### Inconsistent changes {#inconsistent-changes}

A changelog that records only some changes can mislead as much as no changelog. Readers treat it as the full picture. It should be. Leave out trivial changes, but include every notable one. A changelog is only trustworthy if it is kept up to date consistently.

## Changelogs, automation, and LLMs {#automation}

A changelog that follows a consistent shape can be read by tools and by language models, because it was written for people first. There is no separate machine format, and there will not be one: this page is the format. A consistent changelog is easy to parse, a benefit of writing clearly, not a reason to write for machines.

Machines can also help write a changelog. A language model can draft one from a diff in seconds, which is useful as a starting point. But it is now easy to publish a fluent changelog that no one has read. The principle that started this project matters more as machines write more code: **machines can draft, but humans curate**.

A model can't decide what's notable for your readers, or say it plainly for them. If you use a tool for the first draft, give it the brief you would give a contributor: summarize notable, user-facing changes; do not paste a git log; sort each change into one of the six types; explain the reason in the text; mark breaking changes; and remove anything not worth reading. Then read the result before anyone else does.

<aside markdown="1">
If your project uses coding agents, record that brief where they read it, for example an `AGENTS.md` or `CLAUDE.md` file. There is no format to configure; the instructions are the interface.
</aside>

The same caution applies to changelogs generated from commit messages. A convention such as [Conventional Commits][conventional-commits], with tools such as [semantic-release][semantic-release], release-please, Changesets, and git-cliff, reads structured commits to choose the next version and draft a changelog. That can give you a starting point, but a commit and a changelog entry are written for different people, and one does not convert cleanly into the other.

Generating the entry from the commit assumes that every commit belongs in the changelog, and that the right entry is a reworded commit message. Usually it is neither: many commits do not matter to your readers, and the changes that do often span several commits and need to be described from the reader's point of view. Sorting commits by type shortens the list, but it does not make that shift. A generated changelog is raw material at best: a person still has to choose what is notable, group it, and write it for the reader.

Continuous integration can help, but keep it in a supporting role. Use it for mechanical tasks: move the `Unreleased` section into a dated version at release time, check that the file is formatted correctly, and optionally remind a contributor that a change may need an entry. Do not make a changelog edit a required check on every change. That teaches people to add a line to pass the check, which fills the changelog with noise. Let automation handle the mechanics, and leave the judgment to people.

## Less common questions {#less-common}

### What about yanked releases? {#yanked}

A yanked release is a version pulled because of a serious bug or security issue. List it; do not hide it. Mark it like this:

```
## [0.0.5] - 2014-12-13 [YANKED]
```

The `[YANKED]` tag is loud on purpose. People need to notice it, and the brackets make it easy to parse too.

### Should you ever rewrite a changelog? {#rewrite}

Sure. There are always good reasons to improve a changelog. I have opened many pull requests to add missing releases to projects whose changelogs stopped being updated. You may also discover that you forgot to record a breaking change. Fix it, and consider noting the date you updated the entry so readers notice.

### What if the changelog gets too big? {#large-changelog}

A single file is usually fine, even a long one; many projects keep decades of history in one `CHANGELOG.md`. If it becomes hard to manage, you can move old history into separate files, but link the main file and the archives both ways, or readers will not find the older entries. Archive only versions old enough that they will not need editing, and do not delete old entries: someone may still upgrade from an old version.

### How do I avoid changelog merge conflicts? {#merge-conflicts}

A shared `Unreleased` section is convenient, but it can cause merge conflicts when branches are merged often. Short entries, committed on the same branch as the change, help. When conflicts stay frequent, tell your version control system to keep both sides with a union merge (`merge=union` in a `.gitattributes` file).

Higher-volume projects can also keep unreleased entries in a separate file inside a directory such as `changelog.d/`. Branches avoid conflict by not editing the same section of the changelog file. At release time the files can be combined into the `CHANGELOG.md` and removed from the subdirectory. This scales, but it adds complexity. Start with a shared `Unreleased` section. Add a union merge if conflicts become tedious. Move to per-branch files only when nothing else works.

### What about monorepos? {#monorepos}

It depends on whether the repository holds one product or many. Unrelated projects that share a repository each keep their own changelog. A single product made of many parts (say, a framework split into separate libraries) can keep a changelog per component, but should also keep one central changelog. Readers should not have to read a dozen component changelogs to understand what a release means. The per-component changelogs are the detailed record; the central one is the summary.

### Should I link to issues or pull requests? {#linking}

You can, and it is sometimes helpful. Keep two things in mind: links break when a repository moves, and pull request numbers belong to one host, not to your code. Git tags and commit references stay with the repository. Link when it helps, prefer plain prose over a list of bare `(#1234)` references, and use portable references when you want a pointer that will still work later. Collect these as reference-style links at the bottom of the file, the way the version comparisons are, so the prose stays readable and every pointer lives in one place you control.

### Should you credit contributors? {#credits}

The commit history already records who did what, so a changelog does not need to credit anyone. But naming contributors, especially in a notable release, is a common and generous way to recognize their work and encourage more of it. If you do, keep it brief, and remember that a `@handle` belongs to one host, so a name or a link to a profile travels better. For fuller credits, a `CONTRIBUTORS` or `AUTHORS` file keeps them in the repository without crowding the record of what changed.

## About Keep a Changelog {#about}

### Is there a standard changelog format? {#standard}

Not really. The [GNU changelog style guide][gnu-changelog] and the two-paragraph [GNU NEWS file][gnu-news] guideline exist, and neither is enough. Keep a Changelog does not aim to be the one true standard. It aims to show that clear, consistent communication about changes is worth the effort. It started from good practices in open source and applies to any project that needs to communicate its changes.

### What does it deliberately leave out? {#scope}

A convention is defined by what it leaves out as much as by what it includes. Some common requests are deliberate non-goals:

- No new change types: six are enough.
- No machine format, schema, or strict layout: this is the format.
- No tool or service to install: a convention should cost only attention.
- No dependence on a vendor: a changelog is a plain file in your repository.

None of this is fixed; it is open to discussion. But additions to a widely used convention deserve care.

### How can I contribute? {#contribute}

This page is not the truth. It is my carefully considered opinion, with examples and information gathered over years, and it is still a work in progress. Every version was shaped by discussion in the community, and I think the discussion matters as much as the result. So please [contribute][contribute], or start a [conversation][discussions] if you have ideas or need help.

## References {#references}

Keep a Changelog grew from good practices observed in open source, gathered into the convention this page describes, and demonstrated in [its own changelog][kac-changelog]. I went on [The Changelog podcast][changelog-podcast] to talk about why maintainers and contributors should care about changelogs, and about the motivation behind this project.

Since then it has been translated into dozens of languages and adopted by [tens of thousands of open-source projects][adoption-search] whose changelogs note that their format is based on it.

Among the adopters are NASA and the UK's National Archives, the Wikimedia Foundation, and companies such as Cloudflare and Unity, several of which recommend it in their own contributor guides and engineering handbooks.

Its reach extends past software, too. Peer-reviewed research on software versioning and breaking changes cites it, and research-data guidelines such as The Turing Way and the Helmholtz Metadata Collaboration recommend it for tracking changes to scientific datasets.

<!-- Link references, ordered by first appearance above. -->

[versioning-schemes]: https://en.wikipedia.org/wiki/Software_versioning#Schemes
[semver]: https://semver.org/
[iso-8601]: https://www.iso.org/iso-8601-date-and-time-format.html
[calver]: https://calver.org/
[git]: https://en.wikipedia.org/wiki/Git
[vcs]: https://en.wikipedia.org/wiki/Distributed_version_control
[conventional-commits]: https://www.conventionalcommits.org/
[semantic-release]: https://github.com/semantic-release/semantic-release
[gnu-changelog]: https://www.gnu.org/prep/standards/html_node/Style-of-Change-Logs.html#Style-of-Change-Logs
[gnu-news]: https://www.gnu.org/prep/standards/html_node/NEWS-File.html#NEWS-File
[contribute]: https://github.com/olivierlacan/keep-a-changelog
[discussions]: https://github.com/olivierlacan/keep-a-changelog/discussions
[kac-changelog]: https://github.com/olivierlacan/keep-a-changelog/blob/main/CHANGELOG.md
[changelog-podcast]: https://changelog.com/podcast/127
[adoption-search]: https://github.com/search?q=%22based+on+%5BKeep+a+Changelog%5D%28https%3A%2F%2Fkeepachangelog.com%22&type=code
