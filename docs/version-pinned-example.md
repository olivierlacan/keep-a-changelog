# Version-pinned example changelog

How each spec page's hero "Example changelog" stays true to the conventions
that page describes, even after newer spec versions ship.

## The problem

The example changelog shown on every spec page is the project's own
`CHANGELOG.md`, read live from the repository root at build time — the 2.0+
hero figure and the pre-2.0 header `<pre>` both embed it. The live file always
follows the *newest* spec it documents: its preamble links to the newest spec
URL, and new entries adopt whatever conventions that spec recommends.

That's exactly right for the newest version's page, but wrong for older ones.
As reported in [issue #720's comments](https://github.com/olivierlacan/keep-a-changelog/issues/720#issuecomment-4831774411),
the 1.0.0 and 1.1.0 pages were displaying the 2.0.0 example — a changelog
whose preamble declares it follows a spec the page doesn't describe. The same
would happen to `/en/2.0.0/` the day 2.1.0 or 3.0.0 ships.

## Approaches considered

**Tracking branches** — a branch per minor (`2.0`, `2.1`, …) holding a
`CHANGELOG.md` frozen to that track. Rejected: the deploy workflow builds from
a single shallow checkout (no other branches, no tags are fetched), so the
build can't see them without extra CI plumbing; each branch is another thing to
maintain and forget; and copy edits to old entries on `main` would never reach
the pinned views.

**Committed snapshots** — a `changelogs/<version>.md` file frozen at each
release. Rejected for similar reasons: it adds a release-checklist step that's
easy to miss, duplicates content that then drifts, and every patch release on
an old track (translation batches become patches — see
`versioning-policy.md`) would require re-snapshotting.

**Derivation (chosen)** — compute the pinned view from the one live
`CHANGELOG.md` at build time. The changelog is append-mostly and every entry is
dated and versioned, so "the changelog as it stood at the last 2.0.x release"
is reconstructable from today's file.

## How derivation works

`tools/changelog_pin.rb` (pure, unit-tested in `test/changelog_pin_test.rb`;
wired up through the `changelog_example`/`changelog_preview`/
`changelog_example_pinned?` helpers in `config.rb`, the hero figure in
`source/layouts/layout.html.haml`, and the `changelog_example` embed in every
pre-2.0 version page):

- A page shows a pinned view only when the changelog **already documents a
  release on a newer major.minor track** than the page's. This is independent
  of which version the site publishes as its default: the moment the 2.0.0
  entry landed in `CHANGELOG.md`, the 1.x pages pinned to their own era, even
  while 1.1.0 remained the published latest. The newest documented track's
  page — and any still-undocumented draft — keeps showing the live file,
  `Unreleased` section and all.
- The pin cutoff is the **newest release on the page's major.minor track**
  (the 2.0.0 page pins to the last 2.0.x, not to 2.0.0 itself), because patch
  releases ship translations and site fixes without changing the spec.
- Entries newer than the cutoff are dropped, along with their reference-link
  definitions at the bottom of the file.
- The `Unreleased` section keeps its heading — it's part of the format being
  taught — but is emptied, since its contents describe work newer than the
  track.
- The `[unreleased]` compare link is rewritten to diff from the cutoff release,
  and the "based on Keep a Changelog" URL in the preamble is rewritten to the
  page's spec version.
- The caption above the example switches to say the changelog is shown "as of
  the last x.y release".

## What this buys

- `CHANGELOG.md` stays the single source of truth, the same philosophy as the
  release tooling (`tools/changelog_release.rb`).
- No release-time step: the moment the changelog records a release on a newer
  track, the older tracks' pages pin themselves.
- Later copy edits to old entries (typo fixes, clarified wording) still flow
  into the pinned views, and a patch release on an old track moves that track's
  pin forward automatically.

## The trade-off

A derived view is a reconstruction, not a byte-for-byte historical snapshot.
If a future spec restructured the changelog *preamble* itself, the derived
older views would inherit the new preamble shape (minus the rewritten spec
URL). If that ever happens, the derivation rules in `tools/changelog_pin.rb`
are the place to compensate — or that one version can graduate to a committed
snapshot.
