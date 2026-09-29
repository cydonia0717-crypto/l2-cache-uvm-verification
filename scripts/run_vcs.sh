#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
VORTEX="$ROOT/third_party/vortex"
VBUILD="$ROOT/third_party/vortex_build"
TEST=${TEST:-l2_smoke_test}
SEED=${SEED:-1}

[ -d "$VORTEX/hw/rtl" ] || { echo "Run scripts/setup_vortex.sh first"; exit 2; }
[ -d "$VBUILD/hw" ] || { echo "Vortex build headers missing; run scripts/setup_vortex.sh"; exit 2; }
command -v vcs >/dev/null || { echo "VCS not found in PATH"; exit 2; }

INC=(
  "+incdir+$VBUILD/hw" "+incdir+$VORTEX/sw" "+incdir+$VORTEX/hw"
  "+incdir+$VORTEX/hw/rtl" "+incdir+$VORTEX/hw/rtl/libs"
  "+incdir+$VORTEX/hw/rtl/interfaces" "+incdir+$VORTEX/hw/rtl/mem"
  "+incdir+$VORTEX/hw/rtl/cache" "+incdir+$ROOT/tb"
  "+incdir+$ROOT/tb/agents/core" "+incdir+$ROOT/tb/agents/mem"
  "+incdir+$ROOT/tb/env" "+incdir+$ROOT/tb/seq" "+incdir+$ROOT/tb/scoreboard"
  "+incdir+$ROOT/tb/coverage" "+incdir+$ROOT/tb/tests" "+incdir+$ROOT/tb/assertions"
)

mapfile -t IFS < <(find "$VORTEX/hw/rtl/interfaces" -maxdepth 1 -name '*.sv' | sort)
mapfile -t MEM < <(find "$VORTEX/hw/rtl/mem" -maxdepth 1 -name '*.sv' | sort)
mapfile -t LIBS < <(find "$VORTEX/hw/rtl/libs" -maxdepth 1 -name '*.sv' | sort)
mapfile -t CACHE < <(find "$VORTEX/hw/rtl/cache" -maxdepth 1 -name '*.sv' | sort)

vcs -full64 -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps   +define+NDEBUG +define+PERF_ENABLE +define+VX_CFG_XLEN=64 +define+VX_CFG_XLEN_64   -debug_access+all -kdb -lca   -cm line+cond+fsm+tgl+branch   "${INC[@]}"   "$VORTEX/hw/rtl/VX_gpu_pkg.sv"   "${IFS[@]}" "${MEM[@]}" "${LIBS[@]}" "${CACHE[@]}"   "$ROOT/tb/if/l2_core_if.sv" "$ROOT/tb/if/l2_mem_if.sv"   "$ROOT/rtl/l2_cache_dut_wrapper.sv"   "$ROOT/tb/assertions/l2_assertions.sv"   "$ROOT/tb/l2_uvm_pkg.sv" "$ROOT/tb/tb_top.sv"   -top tb_top -o simv

./simv +UVM_TESTNAME="$TEST" +ntb_random_seed="$SEED"   -cm line+cond+fsm+tgl+branch -cm_name "$TEST.$SEED"   -l "${TEST}.${SEED}.log"
