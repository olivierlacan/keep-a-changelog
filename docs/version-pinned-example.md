# Version-pinned example changelog

How each spec page's hero "Example changelog" stays true to the conventions
that page describes, even after newer spec versions ship.

## The problem

The example changelog shown on every 2.0+ spec page is the project's own
`CHANGELOG.md`, read live from the repository root at build time. The live file
always follows the *latest* spec: its preamble links to the newest spec URL,
and new entries adopt whatever conventions the newest spec recommends.

That's exactly right for the latest version's page, but wrong for older ones.
Once 2.1.0 or 3.0.0 ships, a visitor reading `/en/2.0.0/` would see an example
written to conventions the page doesn't describe — a caption claiming "written
using the conventions described below" over a changelog that isn't.

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
wired up through the `changelog_preview`/`changelog_example_pinned?` helpers in
`config.rb` and the hero figure in `source/layouts/layout.html.haml`):

- A page shows a pinned view only when its spec version is **older than the
  published `$last_version`**. The latest version's page — and any newer draft
  being previewed — keeps showing the live file, `Unreleased` section and all.
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
- No release-time step: the moment `$last_version` moves past a version, that
  version's page pins itself.
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
