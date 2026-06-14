#!/usr/bin/env python3
"""Offline stylometric proxy for AI-detection signals.

This is NOT GPTZero. GPTZero's score is driven by a language model's
perplexity (how predictable the text is) and burstiness (how much that
predictability varies sentence to sentence), plus surface features.

Perplexity needs the model GPTZero runs server-side, which isn't reachable
from this sandbox. What this script *can* measure offline:

  * Burstiness    -> variation in sentence length (coefficient of variation
                     and the spread of the distribution). Human prose is
                     "bursty": long complex sentences next to short ones.
                     LLM prose tends toward a uniform mid-length rhythm.
  * Lexical signal -> type/token ratio and repeated openers.
  * Surface tells  -> punctuation and rhetorical patterns that current
                     models overproduce (em dashes, semicolons, the
                     "not X, but Y" / "X isn't just Y, it's Z" frame,
                     tricolons, hedges).

Read the output as "how AI-flavored does the *style* look", not as a verdict.
"""
import re
import sys
import statistics as st
from pathlib import Path


def strip_markdown(text: str) -> str:
    """Reduce a markdown/erb source file to readable prose only."""
    # frontmatter
    text = re.sub(r"^---\n.*?\n---\n", "", text, flags=re.S)
    # fenced code blocks
    text = re.sub(r"```.*?```", " ", text, flags=re.S)
    # html/erb tags and comments
    text = re.sub(r"<!--.*?-->", " ", text, flags=re.S)
    text = re.sub(r"<%.*?%>", " ", text, flags=re.S)
    text = re.sub(r"</?[a-zA-Z][^>]*>", " ", text)
    # link-reference definitions at the bottom: [key]: url
    text = re.sub(r"^\[[^\]]+\]:\s*\S+.*$", "", text, flags=re.M)
    # markdown headings markers, blockquote markers, list bullets
    text = re.sub(r"^\s{0,3}#{1,6}\s*", "", text, flags=re.M)
    text = re.sub(r"^\s*>\s?", "", text, flags=re.M)
    text = re.sub(r"^\s*[-*]\s+", "", text, flags=re.M)
    # inline link [text](url) -> text ; reference link [text][ref] -> text
    text = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\[[^\]]*\]", r"\1", text)
    # inline code, bold/italic markers
    text = re.sub(r"`([^`]*)`", r"\1", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    text = re.sub(r"[_*]", "", text)
    # heading anchors {#id}
    text = re.sub(r"\{#[^}]+\}", "", text)
    return text


SENT_SPLIT = re.compile(r"(?<=[.!?])\s+(?=[A-Z0-9\"'])")
WORD = re.compile(r"[A-Za-z']+")


def sentences(prose: str):
    chunks = []
    for para in prose.split("\n"):
        para = para.strip()
        if not para:
            continue
        for s in SENT_SPLIT.split(para):
            s = s.strip()
            if len(WORD.findall(s)) >= 3:  # ignore fragments/labels
                chunks.append(s)
    return chunks


def analyze(name: str, raw: str):
    prose = strip_markdown(raw)
    sents = sentences(prose)
    words = WORD.findall(prose.lower())
    lengths = [len(WORD.findall(s)) for s in sents]

    n_words = len(words)
    n_sents = len(sents)
    mean_len = st.mean(lengths) if lengths else 0
    stdev_len = st.pstdev(lengths) if len(lengths) > 1 else 0
    cv = (stdev_len / mean_len) if mean_len else 0
    ttr = len(set(words)) / n_words if n_words else 0

    text_low = prose.lower()
    tells = {
        "em dash (—)": prose.count("—") + prose.count(" -- "),
        "semicolons": prose.count(";"),
        "colons (mid-sentence)": len(re.findall(r"\w:\s+[a-z]", prose)),
        "'not X, but/it's Y' frame": len(re.findall(
            r"\b(?:isn't|aren't|not just|is not|won't|doesn't)\b[^.;:]{0,60}?"
            r"\b(?:but|it's|it is|rather|instead)\b", text_low)),
        "tricolon (a, b, and c)": len(re.findall(
            r"\w+,\s+\w+[\w ]*,\s+and\s+\w+", text_low)),
        "hedges (often/usually/rarely/generally)": len(re.findall(
            r"\b(?:often|usually|rarely|generally|typically|tend to|tends to)\b",
            text_low)),
        "'worth' / 'matters' framing": len(re.findall(
            r"\b(?:worth|matters|matter)\b", text_low)),
    }

    # sentence-length histogram buckets
    buckets = {"1-9": 0, "10-19": 0, "20-29": 0, "30-39": 0, "40+": 0}
    for L in lengths:
        if L < 10: buckets["1-9"] += 1
        elif L < 20: buckets["10-19"] += 1
        elif L < 30: buckets["20-29"] += 1
        elif L < 40: buckets["30-39"] += 1
        else: buckets["40+"] += 1

    # repeated sentence openers (first word)
    openers = {}
    for s in sents:
        m = WORD.findall(s)
        if m:
            openers[m[0].lower()] = openers.get(m[0].lower(), 0) + 1
    top_openers = sorted(openers.items(), key=lambda kv: -kv[1])[:5]

    print(f"\n{'='*64}\n{name}\n{'='*64}")
    print(f"words: {n_words}   sentences: {n_sents}")
    print(f"mean sentence length: {mean_len:.1f} words  (stdev {stdev_len:.1f})")
    print(f"burstiness (CV of sentence length): {cv:.2f}")
    print(f"   reference: human nonfiction ~0.5-0.8; uniform LLM prose ~0.3-0.5")
    print(f"type/token ratio (lexical diversity): {ttr:.3f}")
    print(f"sentence-length distribution: " +
          "  ".join(f"{k}:{v}" for k, v in buckets.items()))
    print(f"top sentence openers: " +
          ", ".join(f"{w}({c})" for w, c in top_openers))
    print("surface tells:")
    for k, v in tells.items():
        per100 = (v / n_words * 100) if n_words else 0
        print(f"   {k:<42} {v:>3}  ({per100:.2f}/100 words)")
    return {
        "name": name, "words": n_words, "cv": cv, "ttr": ttr,
        "mean_len": mean_len, "tells": tells,
    }


def main():
    targets = [
        ("KAC 2.0 website prose (en/2.0.0/index.html.md)",
         "source/en/2.0.0/index.html.md"),
        ("KAC CHANGELOG.md 2.0.0 entry", None),  # extracted below
    ]
    root = Path(__file__).resolve().parent.parent

    analyze(targets[0][0], (root / targets[0][1]).read_text())

    # extract just the 2.0.0 entry from CHANGELOG.md
    cl = (root / "CHANGELOG.md").read_text()
    m = re.search(r"## \[2\.0\.0\].*?(?=\n## \[)", cl, flags=re.S)
    analyze(targets[1][0], m.group(0) if m else cl)


if __name__ == "__main__":
    main()
