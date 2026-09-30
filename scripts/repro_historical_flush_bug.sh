#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
VORTEX=${VORTEX_HOME:-"$ROOT/third_party/vortex"}
TARGET="$VORTEX/hw/rtl/cache/VX_cache_flush.sv"
MUT_BUILD="$ROOT/out/verilator/mutation-build"
MUT_OUT="$ROOT/out/mutation/historical-flush-race"
mkdir -p "$MUT_OUT"

fixed='if (mshr_empty && bank_empty) begin'
mutant='if (mshr_empty) begin'

grep -Fq "$fixed" "$TARGET" || {
  echo "[mutation] expected fixed flush guard not found in $TARGET" >&2
  exit 2
}

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
old="if (mshr_empty && bank_empty) begin"
new="if (mshr_empty) begin"
if s.count(old) != 1:
    raise SystemExit(f"expected exactly one fixed guard, found {s.count(old)}")
p.write_text(s.replace(old,new,1))
PY

echo "[mutation] reintroduced Vortex historical flush bug a686ceec parent behavior"
echo "[mutation] fixed guard:   $fixed"
echo "[mutation] mutant guard:  $mutant"
echo "[mutation] stress config: L2 bank LATENCY=4 so bank_empty remains low after MSHR drain"

set +e
VERILATOR_DOCKER=${VERILATOR_DOCKER:-1} \
FORCE_REBUILD=1 \
BUILD_OUT="$MUT_BUILD" \
OUT="$MUT_OUT" \
TEST=l2_flush_pipeline_race_test \
SEED=91 \
BANK_LATENCY=4 \
bash "$ROOT/scripts/run_verilator.sh" >"$MUT_OUT/mutation_console.log" 2>&1
rc=$?
set -e

# A compile/elaboration failure is not evidence that the checker caught the
# historical functional defect.
if [ ! -x "$MUT_BUILD/obj_dir/simv" ]; then
  echo "[mutation] FAIL: mutant did not compile; this is not a valid detection" >&2
  tail -n 80 "$MUT_OUT/mutation_console.log" >&2 || true
  exit 2
fi

if [ "$rc" -eq 0 ]; then
  echo "[mutation] FAIL: historical flush mutation escaped the directed test" >&2
  tail -n 80 "$MUT_OUT/run.log" >&2 || true
  exit 1
fi

if ! grep -Eq 'UVM_ERROR|UVM_FATAL|FLUSH_RACE|read mismatch|writeback mismatch|Assertion' "$MUT_OUT/run.log" "$MUT_OUT/mutation_console.log" 2>/dev/null; then
  echo "[mutation] FAIL: simulation failed without checker/assertion evidence" >&2
  tail -n 100 "$MUT_OUT/mutation_console.log" >&2 || true
  exit 2
fi

echo "[mutation] PASS: directed verification detected the reintroduced historical flush-race defect"
grep -E 'UVM_ERROR|UVM_FATAL|FLUSH_RACE|read mismatch|writeback mismatch|Assertion' "$MUT_OUT/run.log" "$MUT_OUT/mutation_console.log" 2>/dev/null | tail -n 20 || true
