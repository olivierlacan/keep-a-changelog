#!/usr/bin/env bash
#
# One-time setup for the translation-QA triage (LaBSE).
#
# Creates an isolated Python virtualenv at tools/.venv, installs the pinned
# dependencies, and pre-downloads the LaBSE model so later runs are offline and
# deterministic.
#
#   tools/setup.sh            # or: bin/rake translations:setup
#
# Model location: by default the model is cached in your standard Hugging Face
# cache (~/.cache/huggingface) — the conventional spot, shared across projects,
# so it is downloaded only once. To keep it project-local instead, export
# HF_HOME before running, e.g.:
#
#   HF_HOME="$PWD/tools/.models" tools/setup.sh
#
set -euo pipefail

cd "$(dirname "$0")" # tools/

PYTHON="${PYTHON:-python3}"
VENV=".venv"
MODEL="sentence-transformers/LaBSE"

echo "==> Python: $("$PYTHON" --version)"

echo "==> Creating virtualenv at tools/$VENV"
"$PYTHON" -m venv "$VENV"
# shellcheck source=/dev/null
source "$VENV/bin/activate"

echo "==> Installing pinned dependencies (tools/requirements.txt)"
python -m pip install --quiet --upgrade pip
python -m pip install -r requirements.txt

echo "==> Recording exact resolved versions to tools/requirements.lock.txt"
python -m pip freeze > requirements.lock.txt

echo "==> Pre-downloading $MODEL (~1.8 GB on first run; cached for reuse)"
python - <<PY
from sentence_transformers import SentenceTransformer
SentenceTransformer("$MODEL")
print("    model cached and ready.")
PY

cat <<'EOF'

Setup complete. Run the triage with:

    bin/rake translations:qa

or manually:

    source tools/.venv/bin/activate
    ruby translation_coverage.rb --segments --format jsonl > segments.jsonl
    python3 tools/labse_triage.py segments.jsonl --max-similarity 0.7
EOF
