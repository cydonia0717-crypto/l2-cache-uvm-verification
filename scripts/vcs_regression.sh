#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD_OUT=${BUILD_OUT:-"$ROOT/out/vcs/build"}
RUN_ROOT=${RUN_ROOT:-"$ROOT/out/vcs/runs"}
BANK_LATENCY=${BANK_LATENCY:-2}

cases=(
  "l2_smoke_test:1"
  "l2_same_line_merge_test:2"
  "l2_mshr_full_test:3"
  "l2_ooo_refill_test:4"
  "l2_clean_eviction_test:5"
  "l2_dirty_eviction_test:6"
  "l2_bank_hotspot_test:7"
  "l2_random_test:8"
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
  "l2_flush_test:22"
  "l2_set_slice_sweep_test:23"
  "l2_mem_rsp_backpressure_test:24"
  "l2_four_way_residency_test:25"
  "l2_byteen_sweep_test:26"
  "l2_flush_pipeline_race_test:27"
  "l2_plru_victim_test:28"
  "l2_release_coalesce_race_test:29"
  "l2_random_test:31"
  "l2_random_test:32"
  "l2_random_test:33"
  "l2_random_test:34"
  "l2_random_test:35"
)

mkdir -p "$RUN_ROOT"
first=1
for spec in "${cases[@]}"; do
  test_name=${spec%%:*}
  seed=${spec##*:}
  out="$RUN_ROOT/$test_name.$seed"
  echo
  echo "===== VCS $test_name seed=$seed ====="
  FORCE_REBUILD=$first \
  BUILD_OUT="$BUILD_OUT" OUT="$out" BANK_LATENCY="$BANK_LATENCY" \
  TEST="$test_name" SEED="$seed" \
    bash "$ROOT/scripts/run_vcs.sh"
  first=0
done

echo
printf 'VCS regression PASS: %d simulations\n' "${#cases[@]}"

if command -v urg >/dev/null 2>&1; then
  mapfile -t dbs < <(find "$RUN_ROOT" -mindepth 2 -maxdepth 2 -type d -name 'simv.vdb' | sort)
  if [ "${#dbs[@]}" -gt 0 ]; then
    args=()
    for db in "${dbs[@]}"; do args+=( -dir "$db" ); done
    report="$ROOT/out/vcs/urg_report"
    rm -rf "$report"
    mkdir -p "$report"
    urg "${args[@]}" -report "$report"
    echo "URG merged report: $report"
  else
    echo "URG available but no simv.vdb directories were found" >&2
  fi
else
  echo "URG not found; skipping merged VCS coverage report"
fi
