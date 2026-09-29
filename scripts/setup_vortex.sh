#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
VORTEX="$ROOT/third_party/vortex"
BUILD="$ROOT/third_party/vortex_build"
COMMIT=a4afb2351f4b4464a53779874616d95571c376d0

if [ ! -d "$VORTEX/.git" ]; then
  git clone https://github.com/vortexgpgpu/vortex.git "$VORTEX"
fi
git -C "$VORTEX" fetch --depth 1 origin "$COMMIT"
git -C "$VORTEX" checkout --detach "$COMMIT"
mkdir -p "$BUILD"
cd "$BUILD"
"$VORTEX/configure" --xlen=64
printf 'Pinned Vortex ready at %s\nBuild config at %s\n' "$VORTEX" "$BUILD"
