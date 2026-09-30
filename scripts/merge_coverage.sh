#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
RUN_ROOT=${RUN_ROOT:-"$ROOT/out/verilator/runs"}
OUT=${COV_OUT:-"$ROOT/out/verilator/coverage"}
mkdir -p "$OUT"

mapfile -t COV_FILES < <(find "$RUN_ROOT" -type f -name coverage.dat | sort)
if [ "${#COV_FILES[@]}" -eq 0 ]; then
  echo "no coverage.dat files found below $RUN_ROOT" >&2
  exit 2
fi

echo "merging ${#COV_FILES[@]} coverage databases"

if command -v verilator_coverage >/dev/null 2>&1; then
  VCOV=(verilator_coverage)
else
  command -v docker >/dev/null 2>&1 || { echo "verilator_coverage/docker unavailable" >&2; exit 2; }
  VCOV=(docker run --rm -v "$ROOT:$ROOT" -w "$ROOT" --entrypoint verilator_coverage verilator/verilator:latest)
fi

"${VCOV[@]}" --write "$OUT/merged.dat" "${COV_FILES[@]}"
"${VCOV[@]}" --write-info "$OUT/merged.info" "$OUT/merged.dat"
"${VCOV[@]}" --report summary "$OUT/merged.dat" | tee "$OUT/summary.txt"
python3 "$ROOT/scripts/coverage_scope_report.py" "$OUT/merged.dat" "$OUT/scope_summary.txt"

echo "coverage outputs:"
ls -lh "$OUT"
