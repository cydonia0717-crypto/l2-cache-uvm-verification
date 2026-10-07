#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD_OUT=${BUILD_OUT:-"$ROOT/out/verilator/full-build"}
VERILATOR_DOCKER=${VERILATOR_DOCKER:-1}
WITH_MUTATIONS=${WITH_MUTATIONS:-0}

cases=(
  "l2_smoke_test:1"
  "l2_same_line_merge_test:2"
  "l2_mshr_full_test:3"
  "l2_ooo_refill_test:4"
  "l2_clean_eviction_test:5"
  "l2_dirty_eviction_test:6"
  "l2_bank_hotspot_test:7"
  "l2_random_test:8"
)

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

VERILATOR_DOCKER="$VERILATOR_DOCKER" BUILD_OUT="$BUILD_OUT" bash "$ROOT/scripts/extended_regression.sh"
VERILATOR_DOCKER="$VERILATOR_DOCKER" BUILD_OUT="$BUILD_OUT" bash "$ROOT/scripts/random_multiseed.sh"

bash "$ROOT/scripts/merge_coverage.sh"

if [ "$WITH_MUTATIONS" = "1" ]; then
  source "$ROOT/.env.oss" 2>/dev/null || true
  VERILATOR_DOCKER="$VERILATOR_DOCKER" bash "$ROOT/scripts/repro_historical_flush_bug.sh"
  VERILATOR_DOCKER="$VERILATOR_DOCKER" bash "$ROOT/scripts/repro_historical_mshr_release_bug.sh"
fi

echo
echo "Open-source regression PASS: 32 normal simulations"
if [ "$WITH_MUTATIONS" = "1" ]; then
  echo "Historical mutation qualification: PASS"
fi
