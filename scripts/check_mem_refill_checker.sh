#!/usr/bin/env bash
# Negative-control qualification for an independent memory refill payload checker.
# The simulation MUST reject a one-bit corrupted memory response.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD_OUT=${BUILD_OUT:-"$ROOT/out/verilator/ci-build"}
OUT=${OUT:-"$ROOT/out/qualification/corrupt-refill"}
VERILATOR_DOCKER=${VERILATOR_DOCKER:-1}

mkdir -p "$OUT"
echo "[qualification] inject one corrupt bit into the first accepted 64-byte refill"

set +e
INJECT_MEM_RSP_CORRUPT=1 FORCE_REBUILD=0 \
  VERILATOR_DOCKER="$VERILATOR_DOCKER" BUILD_OUT="$BUILD_OUT" OUT="$OUT" \
  TEST=l2_smoke_test SEED=1 bash "$ROOT/scripts/run_verilator.sh" \
  >"$OUT/qualification_console.log" 2>&1
rc=$?
set -e

if [ "$rc" -eq 0 ]; then
  echo "[FAIL] deliberately corrupted memory refill was accepted"
  exit 1
fi
if ! grep -q '\[SB_MEM_DATA\].*refill payload mismatch' "$OUT/run.log"; then
  echo "[FAIL] simulation failed but did not show expected independent refill mismatch"
  tail -n 50 "$OUT/qualification_console.log" || true
  exit 1
fi
if ! grep -Eq 'UVM_ERROR[[:space:]]*:[[:space:]]*[1-9][0-9]*' "$OUT/run.log"; then
  echo "[FAIL] no nonzero UVM_ERROR summary from memory-data checker"
  exit 1
fi

echo "[PASS] injected memory data corruption rejected by SB_MEM_DATA"
grep -m 1 'SB_MEM_DATA.*refill payload mismatch' "$OUT/run.log"
