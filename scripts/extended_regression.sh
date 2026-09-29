#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD_OUT=${BUILD_OUT:-"$ROOT/out/verilator/ci-build"}
VERILATOR_DOCKER=${VERILATOR_DOCKER:-1}

tests=(
  "l2_read_hit_test:11"
  "l2_write_allocate_test:12"
  "l2_partial_write_test:13"
  "l2_mem_backpressure_test:14"
  "l2_core_rsp_backpressure_test:15"
  "l2_multi_bank_test:16"
  "l2_mshr_reuse_test:17"
  "l2_line_offsets_test:18"
  "l2_global_mshr_pressure_test:19"
  "l2_writeback_backpressure_test:20"
  "l2_refill_writeback_overlap_test:21"
)

for spec in "${tests[@]}"; do
  test_name=${spec%%:*}
  seed=${spec##*:}
  echo
  echo "===== $test_name (seed=$seed) ====="
  VERILATOR_DOCKER="$VERILATOR_DOCKER" BUILD_OUT="$BUILD_OUT" \
    TEST="$test_name" SEED="$seed" bash "$ROOT/scripts/run_verilator.sh"
done
