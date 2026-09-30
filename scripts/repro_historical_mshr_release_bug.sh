#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
VORTEX=${VORTEX_HOME:-"$ROOT/third_party/vortex"}
TARGET="$VORTEX/hw/rtl/cache/VX_cache_mshr.sv"
MUT_BUILD="$ROOT/out/verilator/mshr-release-mutation-build"
MUT_OUT="$ROOT/out/mutation/historical-mshr-release-race"
mkdir -p "$MUT_OUT"

fixed="                              && ~(dequeue_fire && (dequeue_id == MSHR_ADDR_WIDTH'(i)))\n                              && ~(finalize_valid && finalize_is_release && (finalize_id == MSHR_ADDR_WIDTH'(i)));"
mutant="                              && ~(dequeue_fire && (dequeue_id == MSHR_ADDR_WIDTH'(i)));"

backup=$(mktemp)
cp "$TARGET" "$backup"
restore() {
  cp "$backup" "$TARGET"
  rm -f "$backup"
}
trap restore EXIT

python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1])
s=p.read_text()
old="""                              && ~(dequeue_fire && (dequeue_id == MSHR_ADDR_WIDTH'(i)))
                              && ~(finalize_valid && finalize_is_release && (finalize_id == MSHR_ADDR_WIDTH'(i)));"""
new="""                              && ~(dequeue_fire && (dequeue_id == MSHR_ADDR_WIDTH'(i)));"""
if s.count(old) != 1:
    raise SystemExit(f"expected exactly one release-exclusion guard, found {s.count(old)}")
p.write_text(s.replace(old,new,1))
PY

echo "[mutation] reintroduced Vortex historical MSHR release/coalesce bug 35e85f6 parent behavior"

set +e
VERILATOR_DOCKER=${VERILATOR_DOCKER:-1} \
FORCE_REBUILD=1 \
BUILD_OUT="$MUT_BUILD" \
OUT="$MUT_OUT" \
TEST=l2_release_coalesce_race_test \
SEED=92 \
bash "$ROOT/scripts/run_verilator.sh" >"$MUT_OUT/mutation_console.log" 2>&1
rc=$?
set -e

if [ ! -x "$MUT_BUILD/obj_dir/simv" ]; then
  echo "[mutation] FAIL: mutant did not compile; not valid bug-detection evidence" >&2
  tail -n 100 "$MUT_OUT/mutation_console.log" >&2 || true
  exit 2
fi

if [ "$rc" -eq 0 ]; then
  echo "[mutation] FAIL: MSHR release/coalesce mutation escaped the directed test" >&2
  tail -n 100 "$MUT_OUT/run.log" >&2 || true
  exit 1
fi

if ! grep -Eq 'UVM_ERROR|UVM_FATAL|REL_COAL|outstanding|Assertion|invalid release|dequeue' "$MUT_OUT/run.log" "$MUT_OUT/mutation_console.log" 2>/dev/null; then
  echo "[mutation] FAIL: simulation failed without checker/assertion evidence" >&2
  tail -n 100 "$MUT_OUT/mutation_console.log" >&2 || true
  exit 2
fi

echo "[mutation] PASS: directed verification detected the reintroduced MSHR release/coalesce defect"
grep -E 'UVM_ERROR|UVM_FATAL|REL_COAL|outstanding|Assertion|invalid release|dequeue' "$MUT_OUT/run.log" "$MUT_OUT/mutation_console.log" 2>/dev/null | tail -n 20 || true
