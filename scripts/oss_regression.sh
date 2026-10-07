#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD_OUT=${BUILD_OUT:-"$ROOT/out/verilator/full-build"}
VERILATOR_DOCKER=${VERILATOR_DOCKER:-1}
WITH_MUTATIONS=${WITH_MUTATIONS:-0}
MANIFEST=${MANIFEST:-"$ROOT/scripts/regression_manifest.txt"}

[ -f "$MANIFEST" ] || { echo "regression manifest not found: $MANIFEST" >&2; exit 2; }
mapfile -t cases < <(grep -Ev '^[[:space:]]*(#|$)' "$MANIFEST")

first=1
for spec in "${cases[@]}"; do
  test_name=${spec%%:*}
  seed=${spec##*:}
  echo
  echo "===== OSS $test_name seed=$seed ====="
  FORCE_REBUILD=$first VERILATOR_DOCKER="$VERILATOR_DOCKER" BUILD_OUT="$BUILD_OUT" \
    TEST="$test_name" SEED="$seed" bash "$ROOT/scripts/run_verilator.sh"
  first=0
done

bash "$ROOT/scripts/merge_coverage.sh"

if [ "$WITH_MUTATIONS" = "1" ]; then
  source "$ROOT/.env.oss" 2>/dev/null || true
  VERILATOR_DOCKER="$VERILATOR_DOCKER" bash "$ROOT/scripts/repro_historical_flush_bug.sh"
  VERILATOR_DOCKER="$VERILATOR_DOCKER" bash "$ROOT/scripts/repro_historical_mshr_release_bug.sh"
fi

echo
printf 'Open-source regression PASS: %d normal simulations\n' "${#cases[@]}"
if [ "$WITH_MUTATIONS" = "1" ]; then
  echo "Historical mutation qualification: PASS"
fi
