# Versioning policy

How Keep a Changelog versions itself, and why adding a translation does not bump
the version.

## The version describes the convention

Keep a Changelog's version numbers (1.0.0, 1.1.0, 2.0.0) describe the
**convention**: the format and the guidance around it. That content is the same
in every language. The number bumps when the convention's content changes (new
guidance, reworded principles, a restructured page), the way 2.0.0 did.

One number quietly does two jobs. It names a version of *the convention* and a
release of *the keepachangelog.com project*. Most of the time those move
together. Translations are the case where they don't, which is what makes the
question feel tricky.

## Translations do not bump the version

A translation makes the same convention readable in another language. It adds
nothing to the format, changes nothing, and removes nothing. In Semantic
Versioning terms it is not even a patch to the spec; it is orthogonal to it.

When a project says it is "based on Keep a Changelog 1.1.0," it is pointing at the
format it follows. A new translation of 1.1.0 changes nothing that project relies
on, so it does not warrant a new version.

## A translation carries the version it translates

Each translation is the rendering of one spec version. The French 2.0.0 page is
the French rendering *of* spec 2.0.0, not a version of its own. A translation's
version label means "which spec version this matches," not "a version of this
translation."

This is how the project already tracks translation work: a language is *at* 1.1.0
or *at* 2.0.0. That measures how complete a translation is against the spec, not a
separate version line. The coverage tooling (`translation_coverage.rb`) reports
languages this way.

## Where translations are recorded, and why a patch release fits

Translations are notable, so they belong in the project's own `CHANGELOG.md`
(which itself uses Keep a Changelog's format). When a batch is worth a dated
marker, collect it into a **patch** release, the way **1.1.1** did.

A patch is the right level under Semantic Versioning. A minor release would signal
new guidance, and a major release a change you might have to react to; a batch of
translations is neither. It changes nothing in the convention, so the smallest
bump is the honest one. The patch number says exactly what happened: the project
shipped, the convention did not change. That gives translators and contributors a
dated marker without telling everyone who follows the format that something they
rely on moved.

So the split holds. The **major and minor** numbers track the convention's
content; a **patch** can mark a project release, such as a set of translations,
that leaves the convention untouched. This also follows the guidance on the page
itself: a changelog records notable changes, and not every notable change is a new
version of the format.

## Why the site says "dozens of languages"

Translation count grows continuously and is not tied to a version, so the page
says the convention has been translated into *dozens* of languages rather than a
fixed number. That avoids pinning a figure that goes stale, and avoids implying a
release every time a language lands. (The exact figure from `config.rb` is
currently 28; the page keeps it deliberately vague.)
