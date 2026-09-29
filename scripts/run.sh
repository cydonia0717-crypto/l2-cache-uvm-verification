#!/usr/bin/env bash
set -euo pipefail
SIM=${SIM:-auto}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
if [ "$SIM" = auto ]; then
  if command -v vcs >/dev/null 2>&1; then SIM=vcs;
  elif command -v verilator >/dev/null 2>&1; then SIM=verilator;
  else echo "No supported simulator found (vcs/verilator)."; exit 2; fi
fi
case "$SIM" in
  vcs) exec "$ROOT/scripts/run_vcs.sh" ;;
  verilator) exec "$ROOT/scripts/run_verilator.sh" ;;
  *) echo "Unsupported SIM=$SIM"; exit 2 ;;
esac
