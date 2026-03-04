#!/usr/bin/env bash
set -euo pipefail

ts(){ date "+%Y-%m-%d %H:%M:%S"; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[$(ts)] WARNING: Not a git repo; skipping GitHub publish."
  exit 0
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
if [[ "$BRANCH" != "main" ]]; then
  echo "[$(ts)] WARNING: Current branch is '$BRANCH' (expected 'main'); skipping publish."
  exit 0
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "[$(ts)] WARNING: Remote 'origin' not configured; skipping publish."
  exit 0
fi

# Stage only hub files to avoid committing unrelated local edits.
git add -- index.html pages/*.html pages/*-steps.txt pages/*.steps.txt .github/workflows/deploy-pages.yml 2>/dev/null || true

if git diff --cached --quiet; then
  echo "[$(ts)] No staged hub changes to publish."
  exit 0
fi

STAMP="$(date '+%Y-%m-%d %H:%M:%S %Z')"
git commit -m "hub: rebuild from MASTER ($STAMP)" >/dev/null

echo "[$(ts)] Pushing hub updates to origin/main..."
git push origin main

echo "[$(ts)] GitHub publish complete."
