# Project Status

## Release-quality baseline

The reproducible reference is GitHub Actions run #81 at commit `03d0b8f6984e9e1a64a12873bf30d3d3ab07d281`.

Result: **PASS**.

Normal regression:

- 27 unique functional/stress test classes
- 5 additional random seeds
- 32 unmutated simulations
- 0 UVM_ERROR
- 0 UVM_FATAL
- 1,234 core-read scoreboard checks
- 871 refill requests
- 14 dirty writebacks
- 2 whole-cache flush completions

Concurrency evidence:

- 8 outstanding misses in one bank
- 32 aggregate outstanding misses across four banks
- same-line pending traffic observed
- out-of-order refill observed
- core-request, core-response and memory-request backpressure observed

Coverage:

- reachable functional: 52 / 52
- cache RTL line: 94.6%
- cache RTL branch: 84.7%
- cache RTL expression: 84.1%
- cache RTL toggle: 61.0%

Negative-control evidence:

- historical flush/pipeline mutation killed by SVA
- historical MSHR release/coalesce mutation killed by SVA

## Measured vs prepared

Measured: Verilator/UVM regression, coverage above, and both mutation runs.

Prepared but not measured in this public environment: full VCS/UVM 1.2 regression, URG merged VCS coverage, and interactive Verdi debug. Those require a local Synopsys installation/license.

## Portfolio claim boundary

This is a verification project around an open-source DUT, not an RTL-design claim. The defensible contribution is the independently built verification environment, directed/random scenario design, checking/assertion strategy, regression automation, measured closure, and mutation evidence.
