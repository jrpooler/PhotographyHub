#!/usr/bin/env bash
set -euo pipefail

ts(){ date "+%Y-%m-%d %H:%M:%S"; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[$(ts)] WARNING: Not a git repo; skipping GitHub publish."
  exit 0
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "[$(ts)] WARNING: Remote 'origin' not configured; skipping publish."
  exit 0
fi

# Keep docs/ in sync so GitHub Pages also updates when source is main/docs.
DOCS_DIR="$ROOT/docs"
mkdir -p "$DOCS_DIR"

rsync -a --delete --exclude ".DS_Store" --exclude "._*" "$ROOT/index.html" "$DOCS_DIR/"
if [[ -d "$ROOT/pages" ]]; then
  rsync -a --delete --exclude ".DS_Store" --exclude "._*" "$ROOT/pages/" "$DOCS_DIR/pages/"
fi
if [[ -d "$ROOT/assets" ]]; then
  rsync -a --delete --exclude ".DS_Store" --exclude "._*" "$ROOT/assets/" "$DOCS_DIR/assets/"
fi
touch "$DOCS_DIR/.nojekyll"

# Strip owner-only tools from the shared/docs hub.
DOCS_INDEX="$DOCS_DIR/index.html"
if [[ -f "$DOCS_INDEX" ]]; then
  tmp_index="$(mktemp)"
  /usr/bin/awk '
    /<!--[[:space:]]*Build & Open Workflow Hub[[:space:]]*-->/ { skip=1; next }
    /<!--[[:space:]]*Edit MASTER-steps\.txt[[:space:]]*-->/ { skip=1; next }
    skip && /<\/a>/ { skip=0; next }
    skip { next }
    { print }
  ' "$DOCS_INDEX" > "$tmp_index"
  mv "$tmp_index" "$DOCS_INDEX"
fi

# Stage only hub files to avoid committing unrelated local edits.
# Use nullglob so missing patterns do not break staging.
shopt -s nullglob
stage_files=(
  index.html
  .github/workflows/deploy-pages.yml
  docs/index.html
  docs/.nojekyll
  pages/*.html
  pages/*-steps.txt
  pages/*.steps.txt
  docs/pages/*.html
)
if [[ -d docs/pages ]]; then
  stage_files+=(docs/pages)
fi
if [[ -d docs/assets ]]; then
  stage_files+=(docs/assets)
fi
if (( ${#stage_files[@]} > 0 )); then
  git add -- "${stage_files[@]}"
fi
shopt -u nullglob

if git diff --cached --quiet; then
  echo "[$(ts)] No staged hub changes to publish."
  exit 0
fi

STAMP="$(date '+%Y-%m-%d %H:%M:%S %Z')"
git commit -m "hub: rebuild from MASTER ($STAMP)" >/dev/null

echo "[$(ts)] Pushing hub updates to origin/main from branch '$BRANCH'..."
if ! git push origin HEAD:main; then
  echo "[$(ts)] Push rejected. Attempting rebase onto origin/main, then retry..."
  git pull --rebase --autostash origin main
  git push origin HEAD:main
fi

echo "[$(ts)] GitHub publish complete."
