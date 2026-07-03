# What's in the Actions list

The Workflows sidebar mixes workflows defined in this directory with entries
GitHub adds on its own, which makes it hard to tell what deploys the site and
what merely validates it. The short version: **only "Deploy site (manual)"
changes keepachangelog.com, and only when run by hand.** Everything else is
validation, release bookkeeping, or GitHub-managed automation.

## Defined in this repo

| Workflow | File | Trigger | What it does |
|----------|------|---------|--------------|
| **CI checks** | [`ci.yml`](ci.yml) | push + PR to `main` | Validation only. Runs the Rake suite (unit tests + full Middleman build) and the axe-core accessibility audit. Never deploys. |
| **Deploy site (manual)** | [`deploy.yml`](deploy.yml) | manual (`workflow_dispatch`) | The only way the live site changes. Builds the production site and pushes it to the `gh-pages` branch that GitHub Pages serves. |
| **Release from changelog** | [`release.yml`](release.yml) | push to `main` touching `CHANGELOG.md`, or manual | Creates tags and GitHub Releases from CHANGELOG.md entries, gated behind the `release` environment's approval. Touches Releases only, never the site. |

## Added by GitHub (no file in this repo)

These appear in the same list but are configured in the repository's
**Settings**, not here:

| Entry | Where it comes from | What it does |
|-------|---------------------|--------------|
| **pages-build-deployment** | GitHub Pages | Runs automatically whenever `gh-pages` is pushed (i.e. right after "Deploy site (manual)") and publishes that branch. It's the second half of every deploy — not a separate deploy path. |
| **CodeQL** | Settings → Code security | GitHub's default-setup code scanning. |
| **Dependabot Updates** | Settings → Code security + [`dependabot.yml`](../dependabot.yml) | Opens dependency update PRs. |
| **Dependency Graph** | Settings → Code security | Indexes the dependency manifest. |

## Retired names

"Ruby" (`ruby.yml`) and "Accessibility" (`accessibility.yml`) were merged into
**CI checks** — same jobs, same check names (`test (3.3)` and `axe`), one
workflow. The old names linger in the sidebar as long as their past runs are
retained.
