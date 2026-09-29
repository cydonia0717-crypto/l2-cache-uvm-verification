#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TOOLS=${TOOLS:-"$ROOT/.tools"}
VORTEX="$ROOT/third_party/vortex"
VBUILD="$ROOT/third_party/vortex_build"
UVM="$ROOT/third_party/uvm"
VERILATOR_SRC="$TOOLS/verilator"
VERILATOR_PREFIX="$TOOLS/verilator-install"

VORTEX_COMMIT=a4afb2351f4b4464a53779874616d95571c376d0
UVM_COMMIT=656f20d087370a7c742e00188d20bbf30fa95339
VERILATOR_TAG=v5.052

mkdir -p "$TOOLS" "$ROOT/third_party"

if command -v apt-get >/dev/null 2>&1; then
  if [ "${SKIP_APT:-0}" != "1" ]; then
    SUDO=""
    [ "$(id -u)" = 0 ] || SUDO=sudo
    $SUDO apt-get update
    $SUDO apt-get install -y git make autoconf g++ perl python3 flex bison help2man z3 libfl-dev
  fi
fi

if [ "${SKIP_VERILATOR_BUILD:-0}" != "1" ]; then
  if [ ! -d "$VERILATOR_SRC/.git" ]; then
    git clone https://github.com/verilator/verilator.git "$VERILATOR_SRC"
  fi
  git -C "$VERILATOR_SRC" fetch --tags --force
  git -C "$VERILATOR_SRC" checkout --detach "$VERILATOR_TAG"
  if [ ! -x "$VERILATOR_PREFIX/bin/verilator" ]; then
    pushd "$VERILATOR_SRC" >/dev/null
    autoconf
    ./configure --prefix="$VERILATOR_PREFIX"
    make -j"$(nproc)"
    make install
    popd >/dev/null
  fi
fi

if [ ! -d "$UVM/.git" ]; then
  git clone https://github.com/verilator/uvm.git "$UVM"
fi
git -C "$UVM" fetch --depth 1 origin "$UVM_COMMIT"
git -C "$UVM" checkout --detach "$UVM_COMMIT"

if [ ! -d "$VORTEX/.git" ]; then
  git clone https://github.com/vortexgpgpu/vortex.git "$VORTEX"
fi
git -C "$VORTEX" fetch --depth 1 origin "$VORTEX_COMMIT"
git -C "$VORTEX" checkout --detach "$VORTEX_COMMIT"
mkdir -p "$VBUILD"
pushd "$VBUILD" >/dev/null
"$VORTEX/configure" --xlen=64
popd >/dev/null

cat > "$ROOT/.env.oss" <<ENV
export UVM_HOME="$UVM/src"
export VORTEX_HOME="$VORTEX"
export VORTEX_BUILD="$VBUILD"
ENV
if [ "${SKIP_VERILATOR_BUILD:-0}" != "1" ]; then
  cat >> "$ROOT/.env.oss" <<ENV
export VERILATOR_ROOT="$VERILATOR_PREFIX/share/verilator"
export PATH="$VERILATOR_PREFIX/bin:\$PATH"
ENV
fi

printf '\nOpen-source simulation stack ready.\n'
if [ "${SKIP_VERILATOR_BUILD:-0}" != "1" ]; then
  printf '  Verilator: %s\n' "$($VERILATOR_PREFIX/bin/verilator --version)"
else
  printf '  Verilator: Docker image verilator/verilator:latest\n'
fi
printf '  UVM:       %s @ %s\n' "$UVM" "$UVM_COMMIT"
printf '  Vortex:    %s @ %s\n' "$VORTEX" "$VORTEX_COMMIT"
printf 'Run: source .env.oss && TEST=l2_smoke_test ./scripts/run_verilator.sh\n'
