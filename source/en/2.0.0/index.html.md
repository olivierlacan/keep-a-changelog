---
title: Keep a Changelog
description: Clearly document the evolution of your projects.
language: en
version: 2.0.0
---

<div class="intro-grid" markdown="1">

<section class="intro-card" markdown="1">
## What's a changelog? {#what}

It's a curated, chronologically ordered list of the notable changes for each version of a project.

</section>

<section class="intro-card" markdown="1">
## Why keep one? {#why}

To make it easy for users and contributors to see the notable changes between each version.

</section>

<section class="intro-card" markdown="1">
## Who needs this? {#who}

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
- Write plainly. Many of your readers are not native English speakers, so favor clear, concise wording.

### Types of changes {#types}

- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Removed` for now removed features.
- `Fixed` for bug fixes.
- `Security` for vulnerabilities.

Usually the right type is clear. Three of them cause the most questions:

- `Fixed`: the behavior was wrong, and is now correct.
- `Changed`: the behavior worked as intended, and now works differently.
- `Security`: the change addresses a vulnerability. It could fit under Fixed or Changed, but its urgency and audience are different.

When you are unsure, ask whether the old behavior was a bug. If it was, use `Fixed`. If it was intentional and you are changing it, use `Changed`.

When a `Security` entry has a CVE identifier, lead with it so readers and security tools can match the entry to the advisory:

```
- CVE-2024-12345: out-of-bounds read when parsing malformed input.
```

<aside markdown="1">
There are only six types on purpose. The type says what kind of change it is. The reason (an improvement, an optimization, a refactor, a performance gain, a dependency update) belongs in the wording of the entry, not in a new type. "Rewrote the JSON parser; about three times faster on large files" says more under `Changed` than a `Performance` heading would. You can add a category if you genuinely need one, but you rarely will: `Improved` and `New` are usually `Changed` and `Added` with the reason in the wording, and `Internal` or `Housekeeping` changes are rarely notable enough to list at all. Keeping to the six leaves every changelog readable the same way, and parseable by the same tools.
</aside>

Two requests are common:

- **Dependencies** are not a type of change. A dependency update can be harmless, a fix, or breaking. If it matters to your users, describe its effect under the right type. If it does not, leave it out.
- **Known issues** are discovered, not changed. Note them on the affected version or in your issue tracker. When one is fixed, it goes under `Fixed`.

### Breaking changes {#breaking}

Mark breaking changes clearly. The version number already signals them (under [Semantic Versioning][semver], a major release is where they belong), but the number is easy to miss, so highlight them in the entry. Breaking changes usually go under `Changed` or `Removed`. Add a short `**Breaking:**` marker so they stand out, and keep them with the type of change they are:

```
- **Breaking:** parse() now returns a result object instead of raising.
```

Be specific about what breaks. "Breaking" only means something once readers know which interface you keep stable: a command line, a library API, a network protocol, a file format, a configuration schema. State which one your versioning scheme covers.

A short upgrade note can sit in the entry itself, such as "rename the `color` option to `theme`." When the steps are substantial, link to them (a migration guide or the release notes) rather than spelling them out here. A long procedure buries what changed and turns a scannable record into a how-to: a different kind of document, for a narrower audience. Keep the `**Breaking:**` marker on the entry itself, within its type, rather than collecting breaks into a separate section, so anyone scanning `Changed` or `Removed` sees them in place.

### Structuring a release {#releasing}

Keep an `Unreleased` section at the top to collect upcoming changes. It shows readers what to expect, and at release time you move its contents into a new version.

A version starts with its number and date, for example `## [1.0.0] - 2017-07-17`. Use the `YYYY-MM-DD` format. It orders from the largest unit to the smallest, avoids the confusion of regional date formats, and is an [ISO standard][iso-8601].

The square brackets around `[1.0.0]` make it a Markdown reference link. Resolve it once at the bottom of the file, pointing each version to a comparison with the one before it:

```
[Unreleased]: https://github.com/your/project/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/your/project/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/your/project/releases/tag/v1.0.0
```

`[Unreleased]` compares the latest tag to `HEAD`, so it always shows what has accrued since the last release, and the oldest version links to its tag, since there is nothing earlier to compare it with. Now every version is tied to its tag and links to the exact diff of what changed: the same association a hosted release page makes for you, kept in a file you own instead of a platform's database. Any host exposes tag and comparison URLs, so the pattern works wherever your code lives, and the link stays out of the heading, so the changelog still reads cleanly.

A version may open with a short summary before the typed sections: a sentence or two on the theme of the release or a notable change. This is optional. Use it when a release is worth introducing, and skip it otherwise.

You do not have to use Semantic Versioning. [Calendar versioning][calver], a plain number, or a date all work; note which scheme you use so readers can read your version numbers. Some projects release continuously and have no version numbers. A changelog still helps: keep dated entries under `Unreleased`.

### Curate, don't accumulate {#curation}

Keeping a changelog is partly an act of restraint. A changelog records _notable_ changes, which means some changes are not notable and do not belong in it. Deciding which is which takes judgment, and that judgment is human.

<aside markdown="1">
Making changes and communicating about changes are two different tasks. Curating a changelog does not mean sorting every commit into a type as you make it. That is tedious, and it is not the goal: write the changelog as a summary for your readers, not as a record of your commits.
</aside>

### What should the file be named? {#filename}

Name it `CHANGELOG.md`. Some projects use `HISTORY`, `NEWS`, or `RELEASES`, but a predictable name makes it easy to find. A changelog does not need to list every change. Version control already does that. It lists the notable ones.

### What goes at the top of the file? {#header}

Open with a `# Changelog` heading and a short, fixed preamble that says what the file is and which conventions it follows:

```
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
```

Stating the conventions you follow tells readers, and tools, what to expect. The first link declares the format; the second names your versioning scheme (Semantic Versioning here, but reference whichever you use). Pin the Keep a Changelog link to the version you follow, so it stays accurate as this page changes.

### Is a changelog the same as release notes? {#release-notes}

No, though they draw from the same material. A changelog is the complete, ongoing record: every notable change, across every version, kept in one file in the repository and written plainly for anyone. Release notes are an announcement for a single release: a curated selection of its headline changes, often with upgrade steps and a marketing voice, published when that version ships. The changelog is the source; release notes are drawn from it and shaped for the announcement. Keep the changelog as the record, and write the release notes from it rather than maintaining two.

This does not have to mean doing the work twice. At release time, the version's section in the changelog is already the draft: copy it into the release, and expand it only if the announcement wants more. Because every version sits under a predictable `## [x.y.z]` heading, a small script can extract that section and create the release without anyone retyping it.

Hosts will also offer to generate the notes for you: GitHub from merged pull requests, GitLab from commit messages. See that offer for what it is. It produces the raw history, written for the people working on the code rather than the people using it, and it keeps your release communication inside the platform, made by its tooling. The convenience is the hook. A changelog you write and own owes nothing to a vendor: a generated draft can be a starting point, but curate it and keep the record in your repository.

Many projects use a host's release system for this instead, such as GitHub Releases or GitLab Releases. These are convenient: they attach notes to a tag, show them on the project page, notify watchers, and collect built files. But the notes live in one platform's database, not in your repository. They do not travel with a `git clone`, and they do not follow you to another host: your history moves, your release notes do not. If the platform changes, or you leave it, that record is stranded.

A changelog avoids this because it is a plain file you own. It can carry the same information these systems present (dated versions, grouped changes, a release summary, links to issues or commits), and it stays in the repository where anyone can read it offline. Keep `CHANGELOG.md` as the canonical record and generate the host's release pages from it. You still get the platform's reach (notifications, a visible page, attached downloads) without depending on it to hold your history.

## What makes a changelog worse? {#bad-practices}

A few habits make a changelog less useful.

### Commit log diffs {#log-diffs}

Do not use a list of commits as a changelog. It is full of noise: merge commits, unclear messages, internal changes. A commit records a step in the source code. A changelog entry records a notable difference, often across several commits, written for the people who use the software.

> A "git log" is the list of commits in a [git][git] repository. We mention git because it is the most common [version control system][vcs], but this applies to any of them: a raw commit history is not a changelog.

### Ignoring deprecations {#ignoring-deprecations}

When someone upgrades, it should be clear what will break. Make it possible to upgrade to a version that lists deprecations, remove what is deprecated, then upgrade to the version that removes them. If you do nothing else, list deprecations, removals, and breaking changes.

### Inconsistent changes {#inconsistent-changes}

A changelog that records only some changes can mislead as much as no changelog. Readers treat it as the full picture. Leave out trivial changes, but include every notable one. A changelog is only trustworthy if it is kept up to date consistently.

## Changelogs, automation, and LLMs {#automation}

A changelog that follows a consistent shape can be read by tools and by language models, because it was written for people first. There is no separate machine format, and there will not be one: this page is the format. A consistent changelog is easy to parse, a benefit of writing clearly, not a reason to write for machines.

Machines can also help write a changelog. A language model can draft one from a diff in seconds, which is useful as a starting point. But it is now easy to publish a fluent changelog that no one has read. The principle that started this project matters more as machines write more code: **machines can draft, but humans curate**. A model cannot decide what is notable for your readers, or say it plainly for them. If you use a tool for the first draft, give it the brief you would give a contributor: summarize notable, user-facing changes; do not paste a git log; sort each change into one of the six types; explain the reason in the text; mark breaking changes; and remove anything not worth reading. Then read the result before anyone else does.

<aside markdown="1">
If your project uses coding agents, record that brief where they read it, for example an `AGENTS.md` or `CLAUDE.md` file. There is no format to configure; the instructions are the interface.
</aside>

The same caution applies to changelogs generated from commit messages. A convention such as [Conventional Commits][conventional-commits], with tools such as [semantic-release][semantic-release], release-please, Changesets, and git-cliff, reads structured commits to choose the next version and draft a changelog. That can give you a starting point, but a commit and a changelog entry are written for different people, and one does not convert cleanly into the other.

A commit message records a step for the people working on the code, so the change can be understood later. A changelog entry tells the people who use the software what a release means for them. Generating the entry from the commit assumes that every commit belongs in the changelog, and that the right entry is a reworded commit message. Usually it is neither: many commits do not matter to your readers, and the changes that do often span several commits and need to be described from the reader's point of view. Sorting commits by type shortens the list, but it does not make that shift. A generated changelog is raw material at best: a person still has to choose what is notable, group it, and write it for the reader.

Continuous integration can help, but keep it in a supporting role. Use it for mechanical tasks: move the `Unreleased` section into a dated version at release time, check that the file is formatted correctly, and optionally remind a contributor that a change may need an entry. Do not make a changelog edit a required check on every change. That teaches people to add a line to pass the check, which fills the changelog with noise. Let automation handle the mechanics, and leave the judgment to people.

## Less common questions {#less-common}

### What about yanked releases? {#yanked}

A yanked release is a version pulled because of a serious bug or security issue. List it; do not hide it. Mark it like this:

```
## [0.0.5] - 2014-12-13 [YANKED]
```

The brackets make the tag easy to notice and easy to parse.

### Should you ever rewrite a changelog? {#rewrite}

You can improve a changelog after a release. A project may forget an entry, or discover a breaking change it did not record. Fixing this is reasonable. When you do, consider noting the date you updated the entry, so readers notice the change.

### What if the changelog gets too big? {#large-changelog}

A single file is usually fine, even a long one; many projects keep decades of history in one `CHANGELOG.md`. If it becomes hard to manage, you can move old history into separate files, but link the main file and the archives both ways, or readers will not find the older entries. Archive only versions old enough that they will not need editing, and do not delete old entries: someone may still upgrade from an old version.

### What about monorepos? {#monorepos}

It depends on whether the repository holds one product or many. Unrelated projects that share a repository each keep their own changelog. A single product made of many parts (say, a framework split into separate libraries) can keep a changelog per component, but should also keep one central changelog. Readers should not have to read a dozen component changelogs to understand what a release means. The per-component changelogs are the detailed record; the central one is the summary.

### Should I link to issues or pull requests? {#linking}

You can, and it is sometimes helpful. Keep two things in mind: links break when a repository moves, and pull request numbers belong to one platform, not to your code. Git tags and commit references stay with the repository. Link when it helps, prefer plain prose over a list of bare `(#1234)` references, and use portable references when you want a pointer that will still work later. Collect these as reference-style links at the bottom of the file, the way the version comparisons are, so the prose stays readable and every pointer lives in one place you control.

### Should you credit contributors? {#credits}

The commit history already records who did what, so a changelog does not need to credit anyone. But naming contributors, especially in a notable release, is a common and generous way to recognize their work and encourage more of it. If you do, keep it brief, and remember that a `@handle` belongs to one platform, so a name or a link to a profile travels better. For fuller credits, a `CONTRIBUTORS` or `AUTHORS` file keeps them in the repository without crowding the record of what changed.

## About Keep a Changelog {#about}

### Is there a standard changelog format? {#standard}

Not a formal one. There were older conventions, such as the [GNU changelog style guide][gnu-changelog] and the [GNU NEWS file][gnu-news], but they were limited. Keep a Changelog does not aim to be the one true standard. It aims to show that clear, consistent communication about changes is worth the effort. It started from good practices in open source and applies to any project that needs to communicate its changes.

### What does it deliberately leave out? {#scope}

A convention is also defined by what it leaves out. Some common requests are deliberate non-goals:

- It will not add more change types. Six are enough; the reason goes in the wording.
- It will not define a machine format, schema, or required layout. This page is the format.
- It will not become a tool or service to install. A convention should cost only attention.
- It will not depend on any host or vendor. A changelog is a plain file in your repository.

None of this is fixed; it is open to discussion. But additions to a widely used convention deserve care.

### How can I contribute? {#contribute}

Keep a Changelog is one carefully considered opinion with examples, not the only way to communicate changes. It has helped many projects, and it is still a work in progress. Each version came from discussion in the community. Please [contribute][contribute] or start a [conversation][discussions] if you need help.

## References {#references}

Keep a Changelog grew from good practices observed in open source, gathered into a [better changelog convention][kac-changelog]. Olivier Lacan discussed the motivation behind it on [The Changelog podcast][changelog-podcast].

Since then it has been translated into dozens of languages and adopted by [tens of thousands of open-source projects][adoption-search] whose changelogs note that their format is based on it.

Among them are companies such as Microsoft, Google, Cloudflare, and Unity; public institutions such as NASA and the UK's National Archives; and the Wikimedia Foundation. Some recommend it in their own contributor guides and engineering handbooks.

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
