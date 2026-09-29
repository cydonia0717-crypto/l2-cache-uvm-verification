#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
VORTEX=${VORTEX_HOME:-"$ROOT/third_party/vortex"}
VBUILD=${VORTEX_BUILD:-"$ROOT/third_party/vortex_build"}
UVM_HOME=${UVM_HOME:-"$ROOT/third_party/uvm/src"}
TEST=${TEST:-l2_smoke_test}
SEED=${SEED:-1}
OUT=${OUT:-"$ROOT/out/verilator/$TEST.$SEED"}

if [ "${VERILATOR_DOCKER:-0}" != "1" ]; then
  command -v verilator >/dev/null || { echo "verilator not found; run scripts/bootstrap_oss.sh"; exit 2; }
else
  command -v docker >/dev/null || { echo "docker not found"; exit 2; }
fi
[ -f "$UVM_HOME/uvm_pkg.sv" ] || { echo "UVM_HOME invalid: $UVM_HOME"; exit 2; }
[ -d "$VORTEX/hw/rtl/cache" ] || { echo "Vortex source missing; run scripts/bootstrap_oss.sh"; exit 2; }
[ -f "$VBUILD/hw/VX_config.vh" ] || { echo "Vortex generated headers missing; run scripts/bootstrap_oss.sh"; exit 2; }

mkdir -p "$OUT"
cd "$OUT"

INC=(
  "+incdir+$UVM_HOME"
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

if [ "${VERILATOR_DOCKER:-0}" = "1" ]; then
  VERILATOR_CMD=(docker run --rm -v "$ROOT:$ROOT" -w "$OUT" --user "$(id -u):$(id -g)" verilator/verilator:5.052)
else
  VERILATOR_CMD=(verilator)
fi

"${VERILATOR_CMD[@]}" --binary --timing --assert --coverage -j "$(nproc)" \
  -Wno-fatal -Wno-lint -Wno-style -Wno-COVERIGN -Wno-MULTITOP \
  --top-module tb_top --Mdir obj_dir -o simv \
  +define+NDEBUG +define+UVM_NO_DPI +define+VX_CFG_XLEN=64 +define+VX_CFG_XLEN_64 \
  "${INC[@]}" \
  "$UVM_HOME/uvm_pkg.sv" \
  "$VORTEX/hw/rtl/VX_gpu_pkg.sv" \
  "${IFS[@]}" "${MEM[@]}" "${LIBS[@]}" "${CACHE[@]}" \
  "$ROOT/tb/if/l2_core_if.sv" "$ROOT/tb/if/l2_mem_if.sv" \
  "$ROOT/rtl/l2_cache_dut_wrapper.sv" \
  "$ROOT/tb/assertions/l2_assertions.sv" \
  "$ROOT/tb/l2_uvm_pkg.sv" "$ROOT/tb/tb_top.sv" \
  2>&1 | tee compile.log

./obj_dir/simv +UVM_TESTNAME="$TEST" +verilator+seed+"$SEED" 2>&1 | tee run.log

if command -v verilator_coverage >/dev/null 2>&1 && [ -f coverage.dat ]; then
  verilator_coverage --write-info coverage.info coverage.dat || true
fi
