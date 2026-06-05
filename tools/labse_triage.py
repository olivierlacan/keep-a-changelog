#!/usr/bin/env python3
"""LaBSE translation-quality triage for Keep a Changelog.

Reads the aligned English<->translation segments produced by

    ruby translation_coverage.rb --segments --format jsonl > segments.jsonl

and scores each pair with LaBSE (Language-agnostic BERT Sentence Embedding),
a fixed, open-source, multilingual model. The cosine similarity between the
English source embedding and the translation embedding estimates how close in
*meaning* the two are. Low scores are candidate mistranslations for a human to
review -- this tool triages, it does not decide.

Why this is auditable: the model is pinned (MODEL_NAME below), embeddings are
deterministic, and the script prints the exact model + library versions it ran
with, so any run is reproducible byte-for-byte on the same inputs.

Dependencies (not vendored -- install explicitly):

    pip install "sentence-transformers>=2.2,<4" "numpy"

The first run downloads the model (~1.8 GB) from Hugging Face. After that it is
fully offline and deterministic.

Usage:

    ruby translation_coverage.rb --segments --format jsonl > segments.jsonl
    python3 tools/labse_triage.py segments.jsonl
    python3 tools/labse_triage.py segments.jsonl --max-similarity 0.7 --format csv
    cat segments.jsonl | python3 tools/labse_triage.py -            # read stdin

Output is sorted ascending by similarity (most suspect first).
"""

import argparse
import json
import sys

# Pinned for reproducibility. LaBSE covers 100+ languages, including every
# language Keep a Changelog is translated into.
MODEL_NAME = "sentence-transformers/LaBSE"


def read_segments(path):
    """Yield {language, version, section, source, target} dicts from JSONL."""
    stream = sys.stdin if path == "-" else open(path, encoding="utf-8")
    try:
        for line_no, line in enumerate(stream, 1):
            line = line.strip()
            if not line:
                continue
            try:
                yield json.loads(line)
            except json.JSONDecodeError as exc:
                sys.exit(f"error: {path}:{line_no}: invalid JSON ({exc})")
    finally:
        if stream is not sys.stdin:
            stream.close()


def score(segments):
    """Attach a cosine similarity in [0, 1] to each segment, in input order."""
    try:
        from sentence_transformers import SentenceTransformer, util
        import sentence_transformers
    except ImportError:
        sys.exit(
            'error: sentence-transformers is not installed.\n'
            '       pip install "sentence-transformers>=2.2,<4" numpy'
        )

    model = SentenceTransformer(MODEL_NAME)

    sources = [s["source"] for s in segments]
    targets = [s["target"] for s in segments]

    # normalize_embeddings makes the dot product a cosine similarity directly.
    src_emb = model.encode(sources, normalize_embeddings=True, convert_to_tensor=True)
    tgt_emb = model.encode(targets, normalize_embeddings=True, convert_to_tensor=True)

    for i, seg in enumerate(segments):
        seg["similarity"] = round(float(util.cos_sim(src_emb[i], tgt_emb[i])), 4)

    return sentence_transformers.__version__


def annotate(segments):
    """Attach each section's peer median and a per-segment delta from it.

    LaBSE similarity has a strong per-section baseline: short sections (e.g. a
    heading) score low for *every* language, so an absolute cutoff mostly surfaces
    hard sections, not mistranslations. The delta from the section's median across
    languages controls for that -- a language that is a low outlier vs its peers on
    the same section is the real signal.
    """
    from statistics import median

    by_section = {}
    for s in segments:
        by_section.setdefault(s["section"], []).append(s["similarity"])
    medians = {sec: median(vals) for sec, vals in by_section.items()}

    for s in segments:
        s["section_median"] = round(medians[s["section"]], 4)
        s["delta"] = round(s["similarity"] - s["section_median"], 4)
    return segments


def select(segments, args):
    """Filter + sort. Relative mode ranks by how far below section peers a segment
    is (real per-language divergence); absolute mode ranks by raw similarity."""
    if args.relative:
        flagged = [s for s in segments if s["delta"] <= args.max_delta]
        flagged.sort(key=lambda s: s["delta"])
    else:
        flagged = [s for s in segments if s["similarity"] <= args.max_similarity]
        flagged.sort(key=lambda s: s["similarity"])
    return flagged


def main():
    parser = argparse.ArgumentParser(description="LaBSE translation-quality triage.")
    parser.add_argument("input", help="segments JSONL file, or - for stdin")
    parser.add_argument("--max-similarity", type=float, default=1.0,
                        help="absolute mode: show pairs at or below this similarity")
    parser.add_argument("--relative", action="store_true",
                        help="rank by how far BELOW a section's peer median a "
                             "translation scores (recommended: cancels section length bias)")
    parser.add_argument("--max-delta", type=float, default=-0.08,
                        help="relative mode: show pairs at least this far below "
                             "their section median (default: -0.08)")
    parser.add_argument("--format", choices=["text", "csv", "json"], default="text")
    args = parser.parse_args()

    segments = list(read_segments(args.input))
    if not segments:
        sys.exit("error: no segments read")

    lib_version = score(segments)
    annotate(segments)
    flagged = select(segments, args)

    if args.format == "json":
        json.dump({"model": MODEL_NAME, "library_version": lib_version,
                   "mode": "relative" if args.relative else "absolute",
                   "segments": flagged}, sys.stdout, ensure_ascii=False, indent=2)
        print()
        return

    if args.format == "csv":
        print("similarity,section_median,delta,language,version,section")
        for s in flagged:
            print(f'{s["similarity"]},{s["section_median"]},{s["delta"]},'
                  f'{s["language"]},{s["version"]},{s["section"]}')
        return

    mode = "below-peer-median" if args.relative else "absolute similarity"
    cutoff = args.max_delta if args.relative else args.max_similarity
    print(f"# model: {MODEL_NAME}  (sentence-transformers {lib_version})")
    print(f"# {len(flagged)} of {len(segments)} segments flagged ({mode}, cutoff {cutoff}), most suspect first")
    print(f"# 'med' = this section's median similarity across all languages; 'd' = sim - med")
    print(f"{'sim':>6} {'med':>6} {'d':>7}  {'lang':<7} {'section':<22} source -> target")
    print("-" * 104)
    for s in flagged:
        src = s["source"][:36].replace("\n", " ")
        tgt = s["target"][:36].replace("\n", " ")
        print(f'{s["similarity"]:>6.3f} {s["section_median"]:>6.3f} {s["delta"]:>+7.3f}  '
              f'{s["language"]:<7} {s["section"]:<22} {src} -> {tgt}')


if __name__ == "__main__":
    main()
