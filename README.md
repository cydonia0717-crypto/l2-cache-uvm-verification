# Non-blocking L2 Cache UVM Verification

A portfolio-grade digital IC verification project using the open-source Vortex cache RTL as DUT and a newly built SystemVerilog/UVM testbench.

## DUT configuration

- 256 KiB, 4-way, 64-byte line
- 4 banks, 2 upstream request ports
- 64-bit word access
- 8-entry MSHR per bank
- write-back + write-allocate
- pseudo-LRU
- tagged memory refill interface with response reordering support

## Why this project

The project is designed around CPU/NPU/SoC memory-subsystem verification topics that are commonly difficult in real designs: MSHR pressure, concurrent misses, same-line dependencies, refill routing, dirty eviction, replacement and multi-layer backpressure.

## Simulation

Primary flow: Linux + Synopsys VCS/Verdi + UVM 1.2.

Open-source CI flow: Verilator v5.052 + Verilator-compatible UVM + pinned Vortex RTL.

```bash
./scripts/bootstrap_oss.sh
source .env.oss
TEST=l2_smoke_test SEED=1 ./scripts/run_verilator.sh
```

Vortex is pinned to commit `a4afb2351f4b4464a53779874616d95571c376d0`.

## Verified regression status

GitHub Actions run #45 completed **19 / 19 tests PASS** with **0 UVM_ERROR / 0 UVM_FATAL**. The verified baseline accumulated **283 core-read data checks**, observed **259 refill requests**, **5 dirty writebacks**, and reached **32 simultaneous memory-side outstanding refills** in the four-bank global-MSHR pressure test.

See [docs/Regression_Report.md](docs/Regression_Report.md) for the per-test evidence. No final functional/code coverage percentage is claimed yet; coverage closure remains a separate task.

## Current verification scope

Implemented first-wave tests include:

- smoke: cold miss / hit / full write / partial write
- MSHR full pressure: 9 same-bank misses against 8 entries per bank
- out-of-order refill
- same-line concurrent miss
- dirty eviction
- dual-port constrained-random stress
- request and response backpressure

The TB contains two active core agents, a reactive memory responder, scoreboard, functional coverage and boundary SVA.

## Authorship / provenance

The Vortex cache RTL is open-source Apache-2.0 code and is **not** claimed as student-authored RTL.

The portfolio contribution is the verification plan, DUT configuration/wrapper, UVM environment, agents, memory model, scoreboard, assertions, coverage, testcase design, regression infrastructure and debug/closure work.

Do not quote a final coverage percentage until it has been measured by a real regression.

See `docs/Verification_Plan.md`, `docs/TB_Architecture.md`, and `docs/Interview_Notes.md`.


## Measured regression status

A green GitHub Actions regression has been completed on the open-source flow. The cache-RTL scoped merged coverage from run #70 was **94.6% line, 84.7% branch, 83.9% expression and 61.0% toggle**, with **100% of reachable functional-coverage bins (52/52)** hit.

The regression has also demonstrated an **8-entry same-bank MSHR saturation/backpressure case** and up to **32 concurrent memory refills across four banks**. See `docs/Regression_Evidence.md` for the measured evidence and the distinction between DUT coverage and unrelated generic Vortex support code.

Historical upstream cache bugs are additionally being used as mutation targets so the project can demonstrate that its corner-case tests detect real classes of cache-control defects rather than only achieving coverage.
