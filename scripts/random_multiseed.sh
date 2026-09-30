#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD_OUT=${BUILD_OUT:-"$ROOT/out/verilator/ci-build"}
VERILATOR_DOCKER=${VERILATOR_DOCKER:-1}

for seed in 31 32 33 34 35; do
  echo
  echo "===== l2_random_test (seed=$seed) ====="
  VERILATOR_DOCKER="$VERILATOR_DOCKER" BUILD_OUT="$BUILD_OUT" \
    TEST=l2_random_test SEED="$seed" bash "$ROOT/scripts/run_verilator.sh"
done
