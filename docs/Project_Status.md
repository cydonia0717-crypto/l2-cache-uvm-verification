# Project Status

## Release-quality baseline

Reproducible qualified PR run: **#91**, commit
`41fa0d7dcdc98e2b1f530a9b4aac67d11496f113`.
Result: **PASS**, including both historical mutation checks.

Normal regression:

- 29 unique directed/stress test classes + 5 additional random seeds
- 34 unmutated simulations, 0 UVM_ERROR / 0 UVM_FATAL
- 1,254 core-read checks; 895 refill requests
- 14 dirty writebacks; 2 whole-cache flush completions
- 8 same-bank / 32 aggregate outstanding miss pressure observed
- 8 legal retired memory-tag reuses verified in MSHR reuse case
- mid-flight reset: 4 outstanding core reads and 4 refills canceled, 4 fresh reads completed
- dual-port byte-disjoint write/readback: 16 observed pairs spanning all four banks

Coverage:

- reachable functional: **55 / 55 = 100%**
- cache RTL line: **94.6%**
- branch: **84.7%**
- expression: **84.4%**
- toggle: **61.2%**

Mutation evidence:

- historical flush/pipeline mutation killed by SVA
- historical MSHR release/coalesce mutation killed by SVA

Run: https://github.com/cydonia0717-crypto/l2-cache-uvm-verification/actions/runs/37733111765

## Measured vs prepared

Measured: Verilator/UVM regression, coverage above, and both mutation runs.

Prepared but not measured in this public environment: full VCS/UVM 1.2 regression, URG merged VCS coverage, and interactive Verdi debug. Those require a local Synopsys installation/license.

## Portfolio claim boundary

This is a verification project around an open-source DUT, not an RTL-design claim. The defensible contribution is the independently built verification environment, directed/random scenario design, checking/assertion strategy, regression automation, measured closure, and mutation evidence.
