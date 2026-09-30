#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
VORTEX=${VORTEX_HOME:-"$ROOT/third_party/vortex"}
VBUILD=${VORTEX_BUILD:-"$ROOT/third_party/vortex_build"}
TEST=${TEST:-l2_smoke_test}
SEED=${SEED:-1}
BANK_LATENCY=${BANK_LATENCY:-2}
BUILD_OUT=${BUILD_OUT:-"$ROOT/out/vcs/build"}
OUT=${OUT:-"$ROOT/out/vcs/runs/$TEST.$SEED"}
FORCE_REBUILD=${FORCE_REBUILD:-0}

[ -d "$VORTEX/hw/rtl" ] || { echo "Run scripts/setup_vortex.sh first"; exit 2; }
[ -d "$VBUILD/hw" ] || { echo "Vortex generated headers missing; run scripts/setup_vortex.sh"; exit 2; }
command -v vcs >/dev/null || { echo "VCS not found in PATH"; exit 2; }

mkdir -p "$BUILD_OUT" "$OUT"

INC=(
  "+incdir+$VBUILD/hw" "+incdir+$VORTEX/sw" "+incdir+$VORTEX/hw"
  "+incdir+$VORTEX/hw/rtl" "+incdir+$VORTEX/hw/rtl/libs"
  "+incdir+$VORTEX/hw/rtl/interfaces" "+incdir+$VORTEX/hw/rtl/mem"
  "+incdir+$VORTEX/hw/rtl/cache" "+incdir+$ROOT/tb"
  "+incdir+$ROOT/tb/agents/core" "+incdir+$ROOT/tb/agents/mem"
  "+incdir+$ROOT/tb/env" "+incdir+$ROOT/tb/seq" "+incdir+$ROOT/tb/scoreboard"
  "+incdir+$ROOT/tb/coverage" "+incdir+$ROOT/tb/tests" "+incdir+$ROOT/tb/assertions"
)

mapfile -t IF_SRCS < <(find "$VORTEX/hw/rtl/interfaces" -maxdepth 1 -name '*.sv' | sort)
mapfile -t MEM_SRCS < <(find "$VORTEX/hw/rtl/mem" -maxdepth 1 -name '*.sv' | sort)
mapfile -t LIB_SRCS < <(find "$VORTEX/hw/rtl/libs" -maxdepth 1 -name '*.sv' | sort)
mapfile -t CACHE_SRCS < <(find "$VORTEX/hw/rtl/cache" -maxdepth 1 -name '*.sv' | sort)

if [ "$FORCE_REBUILD" = "1" ] || [ ! -x "$BUILD_OUT/simv" ]; then
  echo "[compile] VCS/UVM build in $BUILD_OUT"
  cd "$BUILD_OUT"
  vcs -full64 -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps \
    +define+NDEBUG +define+VX_CFG_XLEN=64 +define+VX_CFG_XLEN_64 \
    +define+L2_BANK_LATENCY="$BANK_LATENCY" \
    -debug_access+all -kdb -lca \
    -cm line+cond+fsm+tgl+branch \
    "${INC[@]}" \
    "$VORTEX/hw/rtl/VX_gpu_pkg.sv" \
    "${IF_SRCS[@]}" "${MEM_SRCS[@]}" "${LIB_SRCS[@]}" "${CACHE_SRCS[@]}" \
    "$ROOT/tb/if/l2_core_if.sv" "$ROOT/tb/if/l2_mem_if.sv" \
    "$ROOT/rtl/l2_cache_dut_wrapper.sv" \
    "$ROOT/tb/assertions/l2_assertions.sv" \
    "$ROOT/tb/l2_uvm_pkg.sv" "$ROOT/tb/tb_top.sv" \
    -top tb_top -o simv -l compile.log
else
  echo "[compile] reusing $BUILD_OUT/simv"
fi

cd "$OUT"
echo "[run] TEST=$TEST SEED=$SEED BANK_LATENCY=$BANK_LATENCY"
"$BUILD_OUT/simv" \
  +UVM_TESTNAME="$TEST" +ntb_random_seed="$SEED" \
  -cm line+cond+fsm+tgl+branch \
  -cm_dir "$OUT/simv.vdb" -cm_name "$TEST.$SEED" \
  -l run.log

if grep -Eq 'UVM_(ERROR|FATAL)[[:space:]]*:[[:space:]]*[1-9][0-9]*' run.log; then
  echo "[FAIL] UVM reported one or more errors/fatals"
  grep -E 'UVM_(ERROR|FATAL)[[:space:]]*:' run.log | tail -n 4 || true
  exit 1
fi
