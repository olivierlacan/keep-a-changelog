# How AI-driven does KAC 2.0's language look?

## TL;DR

The **actual GPTZero service could not be run** from the build sandbox (no API
key, and `gptzero.me` is blocked by the network allowlist; its `predict` endpoint
is POST-only so a plain fetch can't drive it). Instead, `tools/ai_style_probe.py`
computes the signals GPTZero is built on that *can* be measured offline —
**burstiness** (sentence-length variation) and surface "tells" — plus lexical
diversity. The LM-perplexity number is the only piece that genuinely requires
GPTZero's server.

On those offline signals, the **2.0 website prose does not look obviously
AI-driven**. It reads as carefully human-edited:

- **Burstiness 0.65** — squarely in the human-nonfiction band (~0.5–0.8);
  uniform LLM output usually lands ~0.3–0.5.
- **Zero em dashes and zero "not X, but Y" / "isn't just… it's…" frames** —
  the two loudest tells of current models are absent.
- The one thing a detector might flag as "too polished" is the heavy
  **colon/semicolon, aphoristic rhythm** ("X; Y. State which one.") — but that's
  a consistent authorial voice, not a model default.

The **CHANGELOG 2.0.0 entry** is too short and too list-structured (348 words,
mostly bullets) for burstiness to mean anything; GPTZero itself warns it needs
~250+ words of running prose. Its prose fragments are clean.

## Measured signals

| Signal | Website prose | CHANGELOG 2.0.0 | Read as |
|---|---|---|---|
| Words / sentences | 3034 / 215 | 348 / 38 | — |
| Mean sentence length | 14.0 | 9.1 | — |
| Burstiness (CV) | **0.65** | 0.35* | website = human range |
| Type/token ratio | 0.268 | 0.606 | low TTR expected at length |
| Em dash | 0 | 0 | tell absent |
| "not X, but Y" frame | 0 | 0 | tell absent |
| Semicolons /100w | 0.59 | 2.59 | elevated = voice |
| Mid-sentence colons /100w | 0.99 | 1.44 | elevated = voice |
| Tricolons /100w | 0.40 | 0.57 | moderate |

\* The changelog CV is low because it is a structured bullet list, not prose;
do not read it as an AI signal.

## Caveats

- This is a **proxy, not GPTZero**. It cannot reproduce GPTZero's perplexity
  model or its trained classifier, only correlated surface signals.
- AI detectors are **unreliable on short and on heavily-edited text** and throw
  false positives on polished technical writing — exactly this genre. Treat any
  single "AI probability" number, GPTZero's included, with skepticism.

## To get a real GPTZero score

Provide a `GPTZERO_API_KEY` and allowlist `api.gptzero.me`, then POST each text
to `https://api.gptzero.me/v2/predict/text` with header `x-api-key`. The
extracted prose is what `ai_style_probe.py` already isolates.

Run the proxy with: `python3 tools/ai_style_probe.py`
