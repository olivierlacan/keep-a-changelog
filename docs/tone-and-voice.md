# Keep a Changelog — tone & voice guide

How we write Keep a Changelog, and the standard the 2.0 rewrite is held to.

## Who we write for

Keep a Changelog says changelogs are *for humans, not machines*. The same belief
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
   understand: *obvious, simply, just, of course, trivially, everyone knows, as
   you'd expect.* If something really is simple, a short sentence shows it — you
   don't need to say so. Never imply that the confused reader is the problem.
3. **Plain over clever.** Avoid idioms, metaphors, wordplay, and cultural
   references. They rarely translate and they slow non-native readers.
   *"Don't bolt on a schema"* → *"Don't add a schema."*
4. **Explain necessary jargon; drop the rest.** When a technical term is the right
   one, use its common form and define it in a few words the first time (as the
   page does for *"git log"*). Prefer plain verbs to insider shorthand: *release*,
   not *ship*; *formatted correctly*, not *well-formed*.
5. **Short sentences.** One idea per sentence. Prefer common words and the active
   voice.
6. **Concise over complete.** Cut words that don't change the meaning. Delete a
   paragraph that repeats a point made elsewhere.
7. **Consistent terms.** Use the same word for the same thing every time —
   changelog, entry, version, release. Don't vary it for style.
8. **Warm, not in-group.** A little personality is welcome — never at the cost of
   clarity, never aimed at one person, and never the kind of joke or reference
   that rewards insiders and leaves everyone else out. This is the voice 2.0 moves
   toward, away from the older, jokier tone.

## Do / don't

| Don't | Do |
|---|---|
| "most of the time the right type is obvious" | "usually the right type is clear" |
| "some projects ship continuously" | "some projects release continuously" |
| "check that the file is well-formed" | "check that the file is formatted correctly" |
| "take the chore out of it, as long as it doesn't become the chore" | "use it for mechanical tasks" |
| "a happy side effect of writing clearly" | "a benefit of writing clearly" |
| "if your project leans on coding agents" | "if your project uses coding agents" |
| phrasal-verb idioms (bolt on, call out, chase down) | plain verbs (add, highlight, find) |

## Quick test before publishing a sentence

- Could a fluent but non-native reader understand it on the first pass?
- Would a translator have to *rephrase* it rather than translate it?
- Would a capable reader who isn't a programmer feel shut out or talked down to?
- Does it say anything a shorter sentence wouldn't?

If any answer is bad, rewrite it.

## Pass it on to maintainers

The guiding principles give maintainers the same advice — *"Write plainly. Many
of your readers are not native English speakers, so favor clear, concise
wording."* Many of their readers aren't immersed in programmer culture either.
Clarity over flourish keeps a changelog easy to read, easy to translate, and open
to everyone who needs it.
