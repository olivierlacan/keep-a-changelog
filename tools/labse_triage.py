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


def main():
    parser = argparse.ArgumentParser(description="LaBSE translation-quality triage.")
    parser.add_argument("input", help="segments JSONL file, or - for stdin")
    parser.add_argument("--max-similarity", type=float, default=1.0,
                        help="only show pairs at or below this similarity (default: all)")
    parser.add_argument("--format", choices=["text", "csv", "json"], default="text")
    args = parser.parse_args()

    segments = list(read_segments(args.input))
    if not segments:
        sys.exit("error: no segments read")

    lib_version = score(segments)
    segments.sort(key=lambda s: s["similarity"])
    flagged = [s for s in segments if s["similarity"] <= args.max_similarity]

    if args.format == "json":
        json.dump({"model": MODEL_NAME, "library_version": lib_version,
                   "segments": flagged}, sys.stdout, ensure_ascii=False, indent=2)
        print()
        return

    if args.format == "csv":
        print("similarity,language,version,section")
        for s in flagged:
            print(f'{s["similarity"]},{s["language"]},{s["version"]},{s["section"]}')
        return

    print(f"# model: {MODEL_NAME}  (sentence-transformers {lib_version})")
    print(f"# {len(flagged)} of {len(segments)} segments at or below "
          f"similarity {args.max_similarity}, most suspect first")
    print(f"{'sim':>6}  {'lang':<7} {'section':<22} source -> target")
    print("-" * 100)
    for s in flagged:
        src = s["source"][:38].replace("\n", " ")
        tgt = s["target"][:38].replace("\n", " ")
        print(f'{s["similarity"]:>6.3f}  {s["language"]:<7} {s["section"]:<22} {src} -> {tgt}')


if __name__ == "__main__":
    main()
