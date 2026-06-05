---
title: Keep a Changelog
description: Don’t let your friends dump git logs into changelogs.
language: en
version: 2.0.0
---

## What is a changelog? {#what}

A changelog is a curated, chronologically ordered list of the notable changes for each version of a project.

## Why keep a changelog? {#why}

To make it easy for users and contributors to see the notable changes between each version.

## Who needs a changelog? {#who}

People do. Whether they are users or developers, the people who use software care about what it does. When it changes, they want to know what changed and why.

## How do I keep a good changelog? {#how}

### Guiding principles {#principles}

- Changelogs are *for humans*, not machines.
- Every version should have an entry.
- Group changes of the same type.
- Make versions and sections linkable.
- List the latest version first.
- Show the release date of each version.
- Note which [versioning scheme](https://en.wikipedia.org/wiki/Software_versioning#Schemes) you use.
- Write plainly. Many of your readers are not native English speakers, so favor clear, concise wording.

### Types of changes {#types}

- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Removed` for now removed features.
- `Fixed` for bug fixes.
- `Security` for vulnerabilities.

Most of the time the right type is obvious. Three of them cause the most questions:

- `Fixed` — the behavior was wrong, and is now correct.
- `Changed` — the behavior worked as intended, and now works differently.
- `Security` — the change addresses a vulnerability. It could fit under Fixed or Changed, but its urgency and audience are different.

When you are unsure, ask whether the old behavior was a bug. If it was, use `Fixed`. If it was intentional and you are changing it, use `Changed`.

<aside markdown="1">
There are only six types on purpose. The type says what kind of change it is. The reason — an improvement, an optimization, a refactor, a performance gain, a dependency update — belongs in the wording of the entry, not in a new type. "Rewrote the JSON parser; about three times faster on large files" says more under `Changed` than a `Performance` heading would.
</aside>

Two requests come up often:

- **Dependencies** are not a type of change. A dependency update can be harmless, a fix, or breaking. If it matters to your users, describe its effect under the right type. If it does not, leave it out.
- **Known issues** are discovered, not changed. Note them on the affected version or in your issue tracker. When one is fixed, it goes under `Fixed`.

### Breaking changes {#breaking}

Mark breaking changes clearly. The version number already signals them — under [Semantic Versioning](https://semver.org/), a major release is where they belong — but the number is easy to miss, so call them out in the entry. Breaking changes usually go under `Changed` or `Removed`. Add a short `**Breaking:**` marker so they stand out, and keep them with the type of change they are:

```
- **Breaking:** parse() now returns a result object instead of raising.
```

Be specific about what breaks. "Breaking" only means something once readers know which interface you keep stable — a command line, a library API, a network protocol, a file format, a configuration schema. State which one your versioning scheme covers.

### Structuring a release {#releasing}

Keep an `Unreleased` section at the top to collect upcoming changes. It shows readers what to expect, and at release time you move its contents into a new version.

A version starts with its number and date, for example `## [1.0.0] - 2017-07-17`. Use the `YYYY-MM-DD` format. It orders from the largest unit to the smallest, avoids the confusion of regional date formats, and is an [ISO standard](https://www.iso.org/iso-8601-date-and-time-format.html).

A version may open with a short summary before the typed sections — a sentence or two on the theme of the release or a notable change. This is optional. Use it when a release is worth introducing, and skip it otherwise.

You do not have to use Semantic Versioning. [Calendar versioning](https://calver.org/), a plain number, or a date all work; note which scheme you use so readers can read your version numbers. Some projects ship continuously and have no version numbers. A changelog still helps: keep dated entries under `Unreleased`.

### Curate, don't dump {#curation}

Keeping a changelog is partly an act of restraint. A changelog records *notable* changes, which means some changes are not notable and do not belong in it. Deciding which is which is the work, and it is work for a person.

<aside markdown="1">
Making changes and communicating about changes are two different tasks. "Don't let your friends dump git logs into changelogs" does not mean "sort every commit into a type as you make it" — that is tedious and beside the point. Write the changelog as a summary for your readers, not as a record of your commits.
</aside>

## What makes a changelog worse? {#bad-practices}

A few habits make a changelog less useful.

### Commit log diffs {#log-diffs}

Do not use a list of commits as a changelog. It is full of noise: merge commits, unclear messages, internal changes. A commit records a step in the source code. A changelog entry records a notable difference, often across several commits, written for the people who use the software.

> A "git log" is the list of commits in a [git](https://en.wikipedia.org/wiki/Git) repository. We mention git because it is the most common [version control system](https://en.wikipedia.org/wiki/Distributed_version_control), but this applies to any of them: a raw commit history is not a changelog.

### Ignoring deprecations {#ignoring-deprecations}

When someone upgrades, it should be clear what will break. Make it possible to upgrade to a version that lists deprecations, remove what is deprecated, then upgrade to the version that removes them. If you do nothing else, list deprecations, removals, and breaking changes.

### Inconsistent changes {#inconsistent-changes}

A changelog that records only some changes can mislead as much as no changelog. Readers treat it as the full picture. Leave out trivial changes, but include every notable one. A changelog is only trustworthy if it is kept up to date consistently.

## Changelogs, automation, and LLMs {#automation}

A changelog that follows a consistent shape can be read by tools and by language models, because it was written for people first. There is no separate machine format, and there will not be one: this page is the format. A consistent changelog is easy to parse — a benefit of writing clearly, not a reason to write for machines.

Machines can also help write a changelog. A language model can draft one from a diff in seconds, which is useful as a starting point. But it is now easy to publish a fluent changelog that no one has read. The principle that started this project matters more as machines write more code: **machines can draft, but humans curate**. A model cannot decide what is notable for your readers, or say it plainly for them. If you use a tool for the first draft, give it the brief you would give a contributor: summarize notable, user-facing changes; do not paste a git log; sort each change into one of the six types; explain the reason in the text; mark breaking changes; and remove anything not worth reading. Then read the result before anyone else does.

<aside markdown="1">
If your project uses coding agents, record that brief where they read it — for example an `AGENTS.md` or `CLAUDE.md` file. There is no format to configure; the instructions are the interface.
</aside>

The same applies to changelogs generated from commit messages. Conventions such as [Conventional Commits](https://www.conventionalcommits.org/), and tools such as [semantic-release](https://github.com/semantic-release/semantic-release), release-please, Changesets, and git-cliff, read structured commits to generate a changelog and choose the next version. They are complementary to this convention: commits are the input, and the changelog is the human-facing output. The result is still a draft. It needs a person to decide what is notable and write it for the reader.

Continuous integration can help, but keep it in a supporting role. Use it for mechanical tasks: move the `Unreleased` section into a dated version at release time, check that the file is well-formed, and optionally remind a contributor that a change may need an entry. Do not make a changelog edit a required check on every change — that teaches people to add a line to pass the check, which fills the changelog with noise. Let automation handle the mechanics, and leave the judgment to people.

## Miscellaneous {#miscellaneous}

### What should the file be named? {#filename}

Name it `CHANGELOG.md`. Some projects use `HISTORY`, `NEWS`, or `RELEASES`, but a predictable name makes it easy to find. A changelog does not need to list every change — version control already does that. It lists the notable ones.

### Is a changelog the same as release notes? {#release-notes}

No. A changelog lives in the repository and records what changed between versions, for anyone. Release notes are a curated announcement for one release: highlights, upgrade steps, and some marketing. Derive release notes from the changelog rather than keeping two records.

Code hosting platforms also let you publish release posts from version tags. These are fine, but they live on one platform and are not part of your repository history. Keep the changelog file as the source, and generate posts from it.

### What about yanked releases? {#yanked}

A yanked release is a version pulled because of a serious bug or security issue. List it; do not hide it. Mark it like this:

```
## [0.0.5] - 2014-12-13 [YANKED]
```

The brackets make the tag easy to notice and easy to parse.

### Should you ever rewrite a changelog? {#rewrite}

You can improve a changelog after a release. A project may forget an entry, or discover a breaking change it did not record. Fixing this is reasonable. When you do, consider noting the date you updated the entry, so readers notice the change.

### What if the changelog gets too big? {#large-changelog}

A single file is usually fine, even a long one; many projects keep decades of history in one `CHANGELOG.md`. If it becomes hard to manage, you can move old history into separate files — but link the main file and the archives both ways, or readers will not find the older entries. Archive only versions old enough that they will not need editing, and do not delete old entries: someone may still upgrade from an old version.

### What about monorepos? {#monorepos}

It depends on whether the repository holds one product or many. Unrelated projects that share a repository each keep their own changelog. A single product with many parts — Ruby on Rails, for example — can keep a changelog per component, but should also keep one central changelog. Readers should not have to read a dozen component changelogs to understand what a release means. The per-component changelogs are the detailed record; the central one is the summary.

### Should I link to issues or pull requests? {#linking}

You can, and it is sometimes helpful. Keep two things in mind: links break when a repository moves, and pull request numbers belong to one platform, not to your code. Git tags and commit references stay with the repository. Link when it helps, prefer plain prose over a list of bare `(#1234)` references, and use portable references when you want a pointer that will still work later.

## About Keep a Changelog {#about}

### Is there a standard changelog format? {#standard}

Not a formal one. There were older conventions — the [GNU changelog style guide](https://www.gnu.org/prep/standards/html_node/Style-of-Change-Logs.html#Style-of-Change-Logs) and the [GNU NEWS file](https://www.gnu.org/prep/standards/html_node/NEWS-File.html#NEWS-File) — but they were limited. Keep a Changelog does not aim to be the one true standard. It aims to show that clear, consistent communication about changes is worth the effort. It started from good practices in open source and applies to any project that needs to communicate its changes.

### What won't Keep a Changelog do? {#scope}

A convention is also defined by what it leaves out. Some common requests are deliberate non-goals:

- It will not add more change types. Six are enough; the reason for a change goes in its wording.
- It will not define a machine format, a schema, or a required file layout. This page is the format, in plain language.
- It will not become a tool or a service you install. It is a convention; following it should cost only attention.
- It will not depend on any one host or vendor. A changelog is a plain file in your repository.

None of this is fixed; it is a considered opinion, open to discussion. But the bar for adding to a widely used convention is high.

### How can I contribute? {#contribute}

Keep a Changelog is one carefully considered opinion, with examples — not the only way to communicate changes. It has helped many projects, and it is still a work in progress. Each version came from discussion in the community. Please [contribute](https://github.com/olivierlacan/keep-a-changelog) or start a [conversation](https://github.com/olivierlacan/keep-a-changelog/discussions) if you need help.

## References {#references}

Keep a Changelog grew from good practices observed in open source, gathered into a [better changelog convention](https://github.com/olivierlacan/keep-a-changelog/blob/main/CHANGELOG.md). Olivier Lacan discussed the motivation behind it on [The Changelog podcast](https://changelog.com/podcast/127).
