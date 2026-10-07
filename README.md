# Non-blocking L2 Cache UVM Verification

Portfolio-grade digital-IC verification project using the open-source Vortex cache RTL as DUT and an independently built SystemVerilog/UVM verification environment.

## DUT configuration

- 256 KiB, 4-way set associative, 64-byte cache line
- 4 banks, 2 upstream request ports, 64-bit word interface
- 8-entry MSHR **per bank** (32 aggregate across four banks)
- write-back + write-allocate
- pseudo-LRU replacement
- tagged refill interface that supports multiple outstanding misses and response reordering
- single clock domain
- normal regression bank latency: 2 cycles; targeted flush-race mutation stress also exercises latency 4

The Vortex RTL is pinned to commit `a4afb2351f4b4464a53779874616d95571c376d0`.

## Verification environment

The testbench contains:

- two active core-side UVM agents;
- a reactive memory agent/model with randomized request backpressure, read latency and out-of-order refill;
- an architectural-memory scoreboard that correlates responses by port/tag and checks dirty writeback data byte by byte;
- functional coverage for operation, ports, address/set/bank classes, outstanding depth, same-line concurrency, reorder and stall events;
- boundary protocol SVA plus white-box invariants for cache-flush and MSHR lifetime hazards;
- Verilator CI and a VCS/Verdi-oriented run script.

## Verified regression status

GitHub Actions **run #81** completed successfully on the open-source Verilator/UVM flow.

The green run executed **27 unique functional/stress test classes**, then five additional random seeds, and finally two historical-bug mutation checks. Across the 32 unmutated simulation runs:

- **0 UVM_ERROR / 0 UVM_FATAL**
- **1,234** core-read data checks
- **871** observed refill requests
- **14** dirty writebacks
- **2** completed whole-cache flush operations
- **8** simultaneous refills in the same-bank MSHR-full scenario
- **32** simultaneous refills across all four banks in global pressure
- request, response and memory-request backpressure were all observed

Measured merged coverage for the **Vortex cache RTL scope**:

| Metric | Result |
|---|---:|
| Line | **94.6%** (87 / 92) |
| Branch | **84.7%** (461 / 544) |
| Expression | **84.1%** (1974 / 2348) |
| Toggle | **61.0%** (23779 / 38962) |
| Reachable functional bins | **100%** (52 / 52) |

The raw functional model has two additional memory-response-stall bins that are classified unreachable for this standalone interface/configuration; they are not counted as reachable closure targets.

Run evidence: https://github.com/cydonia0717-crypto/l2-cache-uvm-verification/actions/runs/36678971383

## Historical bug mutation proof

Two documented upstream Vortex fixes are used as mutation targets. The scripts temporarily restore the pre-fix RTL behavior, rebuild it, and require the verification environment to detect the defect.

1. **Flush/pipeline race — Vortex a686ceec**  
   A white-box SVA checks that the flush controller cannot leave `STATE_WAIT1` while the bank pipeline/request queue is still non-empty. Run #81 killed the mutant with `FLUSH_RACE`.

2. **MSHR release/coalesce race — Vortex 35e85f6**  
   A white-box SVA checks that a new MSHR allocation never links behind an entry being released in the same cycle. Run #81 killed the mutant with `MSHR_RELEASE_COALESCE`.

These are mutation reproductions of known upstream defects, **not** claims of original bug discovery or RTL authorship.

## Quick commands

```bash
make setup
make check
make smoke
make run TEST=l2_mshr_full_test SEED=3
make regression
make qualification
make coverage
```

For a licensed Synopsys environment:

```bash
make vcs-smoke
make vcs-regression
make verdi
```

## Simulation

Primary industry-oriented flow:

```bash
./scripts/setup_vortex.sh
TEST=l2_smoke_test SEED=1 ./scripts/run_vcs.sh
```

Open-source reproducible flow:

```bash
make setup
make smoke
make regression        # 32 normal simulations + coverage
make qualification     # normal suite + two historical mutation checks
```

The canonical 32-run list is stored in `scripts/regression_manifest.txt` and is shared by the one-command open-source and VCS regression wrappers.

## Authorship / provenance

The cache RTL is open-source Apache-2.0 Vortex code. The portfolio contribution is the DUT configuration/wrapper, vPlan, UVM environment, agents, memory model, scoreboard, assertions, functional coverage, testcase design, regression/coverage infrastructure, mutation verification and debug/closure work.

Recommended reading:

- `docs/Project_Status.md` — current measured baseline and claim boundary
- `docs/Verification_Plan.md` — verification objectives and closure criteria
- `docs/TB_Architecture.md` — UVM structure and checking strategy
- `docs/Address_Mapping_and_Tagging.md` — exact bank/set/tag/refill-tag mapping
- `docs/Regression_Report.md` / `docs/Regression_Evidence.md` — measured run evidence
- `docs/Debug_Report.md` — mutation/debug cases
- `docs/VCS_Verdi_Guide.md` — commercial-simulator bring-up
- `docs/Interview_Notes.md` / `docs/Interview_Deep_Dive_CN.md` — interview wording and deep-dive Q&A
- `docs/Study_Guide_CN.md` — suggested code-reading order
- `docs/Resume_Project_Description_CN.md` — resume-ready Chinese wording
