#!/usr/bin/env python3
"""Local GPT-2 perplexity + burstiness — the closest offline stand-in for
GPTZero's core signal.

GPTZero classifies text mainly on (1) perplexity: how surprised a language
model is by each token (AI text is low-perplexity / very predictable), and
(2) burstiness: how much that perplexity varies across sentences (human text
is bursty; AI text is flat). This computes both with a local GPT-2, so no
text leaves the machine and no detection service is called.

Lower perplexity  -> more predictable -> more AI-like.
Lower burstiness  -> flatter          -> more AI-like.
"""
import re
import sys
import math
import statistics as st
from pathlib import Path

import torch
from transformers import GPT2LMHeadModel, GPT2TokenizerFast

# reuse the prose extraction already written for the stylometric probe
sys.path.insert(0, str(Path(__file__).resolve().parent))
from ai_style_probe import strip_markdown, sentences  # noqa: E402

MODEL = "gpt2"  # small model; enough for a relative perplexity signal


def load():
    tok = GPT2TokenizerFast.from_pretrained(MODEL)
    model = GPT2LMHeadModel.from_pretrained(MODEL)
    model.eval()
    return tok, model


@torch.no_grad()
def sentence_perplexity(tok, model, text: str):
    ids = tok(text, return_tensors="pt").input_ids
    if ids.shape[1] < 2:
        return None
    out = model(ids, labels=ids)
    # out.loss is mean negative log-likelihood per token
    return math.exp(out.loss.item())


def analyze(name, raw, tok, model):
    prose = strip_markdown(raw)
    sents = [s for s in sentences(prose)]
    ppls = []
    for s in sents:
        p = sentence_perplexity(tok, model, s)
        if p is not None and math.isfinite(p):
            ppls.append(p)
    if not ppls:
        print(f"{name}: no scorable sentences")
        return

    # whole-text perplexity (one pass over the joined prose)
    whole = sentence_perplexity(tok, model, " ".join(sents))
    mean_ppl = st.mean(ppls)
    median_ppl = st.median(ppls)
    stdev_ppl = st.pstdev(ppls) if len(ppls) > 1 else 0
    burst = stdev_ppl / mean_ppl if mean_ppl else 0

    print(f"\n{'='*60}\n{name}\n{'='*60}")
    print(f"sentences scored: {len(ppls)}")
    print(f"whole-text perplexity:        {whole:8.1f}")
    print(f"mean per-sentence perplexity: {mean_ppl:8.1f}")
    print(f"median per-sentence:          {median_ppl:8.1f}")
    print(f"perplexity burstiness (CV):   {burst:8.2f}")
    lo = sorted(ppls)[:3]
    hi = sorted(ppls)[-3:]
    print(f"lowest sentence ppl (most predictable): "
          + ", ".join(f"{x:.0f}" for x in lo))
    print(f"highest sentence ppl (most surprising): "
          + ", ".join(f"{x:.0f}" for x in hi))


def main():
    root = Path(__file__).resolve().parent.parent
    tok, model = load()
    analyze("KAC 2.0 website prose", (root / "source/en/2.0.0/index.html.md").read_text(), tok, model)
    cl = (root / "CHANGELOG.md").read_text()
    m = re.search(r"## \[2\.0\.0\].*?(?=\n## \[)", cl, flags=re.S)
    analyze("KAC CHANGELOG.md 2.0.0 entry", m.group(0) if m else cl, tok, model)

    # human-written control: an older 1.x changelog entry for comparison
    m11 = re.search(r"## \[1\.1\.2\].*?(?=\n## \[)", cl, flags=re.S)
    if m11:
        analyze("CONTROL: CHANGELOG 1.1.2 entry (pre-2.0, human)", m11.group(0), tok, model)


if __name__ == "__main__":
    main()
