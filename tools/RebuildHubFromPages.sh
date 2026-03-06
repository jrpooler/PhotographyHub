#!/usr/bin/env bash
set -euo pipefail

ts(){ date "+%Y-%m-%d %H:%M:%S"; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_SCRIPT="$ROOT/tools/BuildAllFromMaster.sh"

echo "[$(ts)] RebuildHubFromPages.sh is deprecated."
echo "[$(ts)] Redirecting to BuildAllFromMaster.sh so MASTER-steps.txt changes and timestamps are applied."

if [[ ! -x "$BUILD_SCRIPT" ]]; then
  echo "[$(ts)] ERROR: Build script not executable: $BUILD_SCRIPT"
  exit 1
fi

exec "$BUILD_SCRIPT" "$@"
