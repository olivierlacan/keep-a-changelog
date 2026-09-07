# Keep a Changelog — tone & voice guide

How we write Keep a Changelog, and the standard the 2.0 rewrite is held to.

Two failure modes bracket this guide. On one side is the in-group voice: jokes,
idioms, and shorthand that reward insiders and leave everyone else out. On the
other is the sanitized voice: prose so careful and generic that it could have
been written by a committee, a marketing department, or a language model. Keep
a Changelog has drifted toward both at different times. The guide steers
between them: plain enough for anyone, and still recognizably written by
people who care.

## Who we write for

Keep a Changelog says changelogs are _for humans, not machines_. The same belief
shapes how this page is written: it is for **all** humans, not only expert
programmers. Two readers are easy to leave behind, and we write for both.

- **People who don't read English as a first language.** Every translator is one,
  and the page lives in dozens of languages. Idioms, wordplay, cultural
  references, and long sentences make their work harder and the result worse.
- **People who aren't steeped in programmer culture.** Changelogs are kept and
  read by writers, designers, product people, and newcomers — not just senior
  engineers. A lot of technical writing quietly signals who belongs and who
  doesn't. We do the opposite: we explain, we don't assume, and we never make a
  reader feel they should already know.

Clarity here isn't only courtesy. A page that's easy to understand is easy to
translate, easy to apply, and easy to trust.

## Principles

1. **Lead with the point.** State the recommendation first, then the reason. A
   reader who stops after the first sentence should still get the conclusion.
2. **Don't gatekeep.** Cut words that quietly tell a reader they should already
   understand: _obvious, simply, just, of course, trivially, everyone knows, as
   you'd expect._ If something really is simple, a short sentence shows it — you
   don't need to say so. Never imply that the confused reader is the problem.
3. **Plain over clever.** Avoid idioms, metaphors, wordplay, and cultural
   references. They rarely translate and they slow non-native readers.
   _"Don't bolt on a schema"_ → _"Don't add a schema."_
4. **Explain necessary jargon; drop the rest.** When a technical term is the right
   one, use its common form and define it in a few words the first time (as the
   page does for _"git log"_). Prefer plain verbs to insider shorthand: _release_,
   not _ship_; _formatted correctly_, not _well-formed_.
5. **Short sentences.** One idea per sentence. Prefer common words and the active
   voice.
6. **Concise over complete.** Cut words that don't change the meaning. Delete a
   paragraph that repeats a point made elsewhere.
7. **Consistent terms.** Use the same word for the same thing every time —
   changelog, entry, version, release. Don't vary it for style.
8. **Warm, not in-group.** A little personality is welcome — never at the cost of
   clarity, never aimed at one person, and never the kind of joke or reference
   that rewards insiders and leaves everyone else out. Plain does not mean flat.
9. **Opinionated peer, not corporate textbook.** Write as if you are explaining
   best practices to a peer you respect, and say what you think. Keep a Changelog
   exists because someone was fed up with git logs passed off as changelogs, and
   the page should still sound like it. Do not reach for sanitized value
   propositions or textbook neutrality. Keep memorable, opinionated wording
   when it does not cost clarity. The original tagline, _"Don't let your
   friends dump git logs into changelogs"_, was retired because it leaned on an
   English idiom, not because it had an opinion. Whatever replaces it should
   still take a position.
10. **Keep the first person and direct address.** "I", "we", and "you" are not
    flaws to edit out. This is a community-driven opinion written by people, not
    an ISO standard, and the voice should feel like it comes from humans, for
    humans. Say "we recommend" and "you can", not "it is recommended" and "one
    may". Cut a first-person passage only when it is about the author rather
    than the reader.
11. **No buffer sentences.** Delete any sentence that exists only to bridge two
    ideas or to announce what comes next: _"Here are a few ways to think about
    this."_ _"Usually the right type is clear. Three of them cause the most
    questions:"_ _"A few habits make a changelog less useful."_ If the list or
    paragraph that follows makes sense without the sentence, the sentence goes.
12. **No algorithmic phrasing.** When helping a reader choose between options,
    do not spell out the exact thought process as a flowchart: _"If it was a
    bug, use Fixed. If it was intentional, use Changed."_ Give the distinction
    and a brief, concrete example, then trust the reader to apply it.

## Do / don't

| Don't                                                              | Do                                           |
| ------------------------------------------------------------------ | -------------------------------------------- |
| "most of the time the right type is obvious"                       | (delete it, or say which types are confused) |
| "some projects ship continuously"                                  | "some projects release continuously"         |
| "check that the file is well-formed"                               | "check that the file is formatted correctly" |
| "take the chore out of it, as long as it doesn't become the chore" | "use it for mechanical tasks"                |
| "a happy side effect of writing clearly"                           | "a benefit of writing clearly"               |
| "if your project leans on coding agents"                           | "if your project uses coding agents"         |
| phrasal-verb idioms (bolt on, call out, chase down)                | plain verbs (add, highlight, find)           |
| "if conflicts get tedious"                                         | "if conflict becomes tedious"
| a tagline that could sit on any product page                       | a line that takes a position on what a changelog is for |
| "Usually the right type is clear. Three of them cause the most questions:" | (delete it; start the list)              |
| "If it was a bug, use `Fixed`. If it was intentional, use `Changed`." | "A crash is `Fixed`. A new default is `Changed`." |
| "It is recommended that the changelog be kept in the repository."    | "Keep the changelog in the repository."      |
| "One carefully considered opinion"                                  | "My carefully considered opinion"            |

## Tells of machine-written prose

Language models helped edit the 2.0 page, and their defaults leaked into it: a
sterile tagline, flowchart explanations, transition sentences that say nothing,
and every opinion flattened into neutral instruction. These are the patterns to
watch for, whether the draft came from a model or from a tired human.

- **Generic value propositions.** A tagline or opening that could sit on any
  product's landing page. If it has no opinion, it is not ours.
- **Buffer and transition sentences.** "Usually the right type is clear."
  "There are a few ways to approach this." "Two other requests are common:"
  They pad, and they dilute.
- **Flowchart explanations.** "If X, use A. If Y, use B." A reader is not a
  branch statement; give the distinction and an example.
- **Impersonal hedging.** "It is recommended", "one might consider", "can be
  useful". Say who recommends it and why, in the first person if that is who.
- **Over-tidy structure.** Every idea in a labeled bucket, every section the
  same shape, no narrative between them. Structure should serve the reader's
  questions, not a table of contents.
- **Symmetry for its own sake.** Three balanced bullets where two honest ones
  would do.

Plainness is still the goal. The fix for a machine-flavored sentence is not a
joke or an idiom; it is a shorter, more direct sentence with a point of view.

## Quick test before publishing a sentence

- Could a fluent but non-native reader understand it on the first pass?
- Would a translator have to _rephrase_ it rather than translate it?
- Would a capable reader who isn't a programmer feel shut out or talked down to?
- Does it say anything a shorter sentence wouldn't?
- Does it sound like a person with an opinion wrote it, or like a manual?
- Does it exist only to lead into the next sentence?

If any answer is bad, rewrite it.

## Pass it on to maintainers

The guiding principles give maintainers the same advice — _"Write plainly. Many
of your readers are not native speakers, so favor clear, concise
wording."_ Many of their readers aren't immersed in programmer culture either.
Clarity over flourish keeps a changelog easy to read, easy to translate, and open
to everyone who needs it.
