# Working on Keep a Changelog

This file explains why the project is built the way it is. When a change
conflicts with these principles, the principles win.

How-to guidance — setup, common tasks, and the translation workflow — lives
exclusively in [CONTRIBUTING.md](CONTRIBUTING.md). Do not repeat it here;
point to it instead.

## What this project is

Keep a Changelog is a set of mindful guidelines for human-centered change
communication. It is not a spec for people to robotically validate against.
The site exists to help people communicate software changes to other humans,
and every decision — in the writing and in the code — serves that goal.

The project has one maintainer, myriad contributors, and an oversized impact
on how software changes are communicated around the world. Most of that impact
comes from refusing easy tropes: we do not create or endorse specific tools,
we do not follow conventions blindly when they make little sense, and we do
not tell people what to do without regard for their specific contexts.

Apply the same judgment to the project itself. Favor simplicity, and when a
rule needs to be strict, make the reasoning for that strictness clear.

## Technical principles

**No backend.** The site is static HTML, built once and served from GitHub
Pages. This keeps hosting simple, cheap, and durable. Do not introduce
anything that requires a server, a database, or a build service beyond the
existing static build.

**Ruby at heart, CLI-based.** This is a Ruby project (Middleman, Rake,
Minitest), and every workflow runs from the command line ([CONTRIBUTING.md](CONTRIBUTING.md)
lists the tasks). Prefer extending the existing Ruby and Rake tooling over
adding new toolchains. Small exceptions exist where a tool is clearly the
right one for the job (Playwright for cross-browser visual regression, a
Python script for translation QA scoring) — they are dev-only and never part
of the shipped site.

**Boring is fine.** We do not need the most hyped language or framework.
The measure of a tool is whether the project is hindered without it, not
whether it is popular. Before proposing a migration or a new dependency, ask
what problem it solves that the current setup cannot.

**Translations are a first-class concern.** The site's incredible number of
community-created translations exists because translating and managing
versions is deliberately accessible — to readers and to contributors. A
translator can edit plain markup without understanding the build (the workflow
is in [CONTRIBUTING.md](CONTRIBUTING.md)). Protect that: any change to how
pages are structured or versioned must remain easy for a non-programmer
translator to follow.

## How we use LLMs

Keep a Changelog has one maintainer and myriad contributors. Keeping a free
open source project like this alive involves complicated logistics: dozens of
languages, several spec versions in each, and a steady stream of contributions
to review. That work does not happen without automation — and even automation
requires maintenance. LLMs help carry that load, within strict limits, because
wasting resources is antithetical to what this project stands for.

LLMs are **not** used to:

- **Replace translators.** Translations are created and reviewed by people who
  speak the language and know the culture. No model output can substitute for
  that judgment.
- **Decide what Keep a Changelog says.** The guidelines are human positions,
  reasoned about and owned by humans.
- **Spend tokens on needless features.** If a feature would not exist without
  an LLM to justify it, it should not exist.

LLMs **are** used to:

- **Build reusable tools that do not need an LLM to run.** The translation
  coverage lint, the semantic QA pipeline, and the version routing tests are
  ordinary scripts anyone can run, offline, for free, forever. An LLM may help
  write a tool once; the tool must then stand on its own.
- **Validate accessibility, design, and functionality requirements** — checks
  a single maintainer could not perform by hand across every language, version,
  and browser.

The most daunting recurring problem this addresses is translation upkeep.
Every version-specific translation must:

1. exist — or the site must give clear guidance for contributing one;
2. be accurate and consistent with the original English guidelines, while
   remaining understandable in its own language and culture.

Tooling helps check these. Humans decide them.

## Writing and content

The content is held to `docs/tone-and-voice.md`. In short: write plainly,
lead with the point, don't gatekeep, and prefer wording a non-native reader
can understand on the first pass and a translator can translate rather than
rephrase. This applies to site content, and it is a good default for
documentation and commit messages too.

Guidelines on the site should explain their reasoning. A reader should be able
to disagree intelligently with any recommendation we make, because we told
them why we make it.
