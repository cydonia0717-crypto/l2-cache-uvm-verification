# Regression Evidence

All values below are taken from actual GitHub Actions logs; they are not estimated resume targets.

## Current green regression

- Workflow: `oss-smoke`
- Verified PR qualification: **run #95**, commit `cc7a6c60d70c3daaf11345d89e4b7dff8089afdf`
- Result: **PASS**
- Simulator: Verilator/UVM open-source CI against pinned Vortex cache RTL
- 29 unique functional/stress test classes + five additional random seeds
- 34 normal simulations with **0 UVM_ERROR / 0 UVM_FATAL**

| Observation | Measured |
|---|---:|
| Core-read scoreboard checks | **1,254** |
| UVM scoreboard errors | **0** |
| Memory-side refill requests | **895** |
| Completed 512-bit refill payload checks | **891** |
| Refill payload mismatches in normal tests | **0** |
| Refill requests deliberately aborted by reset | **4** |
| Dirty writebacks | **14** |
| Whole-cache flush completions | **2** |
| Peak outstanding refills | **32** |
| Core-request stall cycles | **3,552** |
| Core-response stall cycles | **126** |
| Memory-request stall cycles | **210** |

The same-bank MSHR-full test reaches **8** outstanding refills and stalls a
ninth; the global pressure test reaches **32**. The lifecycle case observes
**8 legal retired memory-tag reuses**. The reset test aborts **4** outstanding
core reads / **4** refills, then completes **4** new reads. The dual-port
test observes **16 byte-disjoint same-word write pairs** across four banks,
followed by clean readbacks.

## Independent checker negative control

PR run **#95** also performs a corrupted memory refill payload negative
control. On a full-byte-enable write-allocate miss, the reactive memory model
flips one bit in the refill line. The independent DRAM image detects
`SB_MEM_DATA: refill payload mismatch`, and the test verifies that the
subsequent Core readback remained correct after the write overwrote the
corrupted byte. **The controlled bad simulation must fail**, while the CI
qualification stage must pass by recognizing the expected failure.

The two historical Vortex RTL mutation tests remain independent gates. The
refill corruption is a **testbench checker qualification**, not an original
RTL bug discovery.

## Merged coverage

| Metric | Vortex cache RTL scope |
|---|---:|
| Line | **94.6%** (87 / 92) |
| Branch | **84.7%** (461 / 544) |
| Expression | **84.4%** (1982 / 2348) |
| Toggle | **61.2%** (23851 / 38962) |

Reachable functional coverage: **55 / 55 = 100%**. Two raw memory-response
stall bins are classified unreachable for this standalone interface configuration.
Code-coverage scopes exclude generic Vortex infrastructure and UVM code.

## Historical mutation evidence

Run #91 also performs two negative-control checks against known upstream Vortex fixes.

### Flush/pipeline race — a686ceec

The script reintroduces the old `mshr_empty`-only guard. The mutant compiles, then the bound assertion detects:

```text
FLUSH_RACE: flush left WAIT1 while bank pipeline/request queue was not empty
```

Result: **mutation killed**.

### MSHR release/coalesce race — 35e85f6

The script removes the same-cycle release exclusion from `addr_matches`. The mutant compiles, then the bound assertion detects:

```text
MSHR_RELEASE_COALESCE: allocation linked behind an entry released in the same cycle
```

Result: **mutation killed**.

Run: https://github.com/cydonia0717-crypto/l2-cache-uvm-verification/actions/runs/37765145449
