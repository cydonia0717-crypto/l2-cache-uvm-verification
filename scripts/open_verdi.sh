#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD_OUT=${BUILD_OUT:-"$ROOT/out/vcs/build"}
FSDB=${FSDB:-}
TOP=${TOP:-tb_top}

command -v verdi >/dev/null 2>&1 || {
  echo "Verdi not found in PATH. Load the Synopsys environment first." >&2
  exit 2
}

DBDIR="$BUILD_OUT/simv.daidir"
if [ ! -d "$DBDIR" ]; then
  echo "VCS debug database not found: $DBDIR" >&2
  echo "Run a VCS build first, for example:" >&2
  echo "  TEST=l2_smoke_test bash scripts/run_vcs.sh" >&2
  exit 2
fi

args=(-dbdir "$DBDIR" -top "$TOP")
if [ -n "$FSDB" ]; then
  [ -f "$FSDB" ] || { echo "FSDB not found: $FSDB" >&2; exit 2; }
  args+=(-ssf "$FSDB")
fi

echo "Launching: verdi ${args[*]}"
exec verdi "${args[@]}"
