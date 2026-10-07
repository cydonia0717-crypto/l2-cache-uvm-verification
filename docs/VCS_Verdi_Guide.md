# VCS / Verdi Bring-up Guide

This project has a measured public baseline on Verilator/UVM. The VCS/Verdi flow is provided as the industry-oriented local flow for machines with Synopsys licenses.

## 1. Prerequisites

Expected tools in PATH:

- vcs
- urg for merged coverage
- verdi for debug
- Git, Bash and Python 3

The repository does not bundle Synopsys software or licenses.

## 2. Fetch the pinned DUT

Run: `bash scripts/setup_vortex.sh`

Vortex is pinned to commit `a4afb2351f4b4464a53779874616d95571c376d0`.

## 3. Static check

Run: `python3 scripts/check_project.py`

Do this before compiling. It catches missing files, broken include paths and configuration drift.

## 4. Run one smoke test

Run: `TEST=l2_smoke_test SEED=1 bash scripts/run_vcs.sh`

The compile uses SystemVerilog, UVM 1.2, `-debug_access+all -kdb`, and line/condition/FSM/toggle/branch coverage. The compiled image is reused from `out/vcs/build`, while every test/seed gets its own directory under `out/vcs/runs/`.

A run is treated as failed when the UVM summary contains a non-zero error or fatal count.

## 5. Run the full regression

Run: `bash scripts/vcs_regression.sh`

This executes the same 27 unique functional/stress tests plus five additional random seeds used by the measured open-source baseline. If `urg` is available, the per-test coverage databases are merged into `out/vcs/urg_report/`.

Do not quote a VCS/URG coverage percentage on a resume until this flow has actually been run on a licensed machine.

## 6. Open Verdi

After a VCS build, run: `bash scripts/open_verdi.sh`

The launcher opens the KDB under `out/vcs/build/simv.daidir`. If a local setup also generates FSDB, use `FSDB=/path/to/wave.fsdb bash scripts/open_verdi.sh`.

The repository intentionally does not force FSDB system tasks into the default TB because FSDB PLI availability differs across installations.

## 7. First signals to inspect

For miss/refill debug, start with the boundary:

- core request valid/ready/rw/address/tag
- core response valid/ready/data/tag
- memory request valid/ready/rw/address/tag
- memory response valid/ready/data/tag

Then descend into the selected bank and inspect MSHR allocate/finalize/dequeue, `mshr_alm_full`, pipeline stages `st0/st1/stC`, hit/miss, victim way, memory-request queue push/pop, and flush state with `mshr_empty/bank_empty`.

For out-of-order refill, correlate the external memory tag with the bank/MSHR and then with the original core request tag.

## 8. Useful commands

- `TEST=l2_mshr_full_test SEED=3 bash scripts/run_vcs.sh`
- `FORCE_REBUILD=1 TEST=l2_smoke_test bash scripts/run_vcs.sh`
- `BANK_LATENCY=4 TEST=l2_flush_pipeline_race_test bash scripts/run_vcs.sh`
- `make vcs-smoke`
- `make vcs-regression`
- `make verdi`
