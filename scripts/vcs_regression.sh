#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD_OUT=${BUILD_OUT:-"$ROOT/out/vcs/build"}
RUN_ROOT=${RUN_ROOT:-"$ROOT/out/vcs/runs"}
BANK_LATENCY=${BANK_LATENCY:-2}

MANIFEST=${MANIFEST:-"$ROOT/scripts/regression_manifest.txt"}
[ -f "$MANIFEST" ] || { echo "regression manifest not found: $MANIFEST" >&2; exit 2; }
mapfile -t cases < <(grep -Ev '^[[:space:]]*(#|$)' "$MANIFEST")
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
