# Regression Evidence

All values below are taken from actual GitHub Actions logs; they are not estimated resume targets.

## Current green regression

- Workflow: `oss-smoke`
- GitHub Actions run: **#81**
- Commit: `03d0b8f6984e9e1a64a12873bf30d3d3ab07d281`
- Result: **PASS**
- Simulator: Verilator/UVM open-source CI flow
- DUT: pinned Vortex cache RTL

The run executed 27 unique functional/stress test classes plus five additional random seeds. Across the resulting **32 unmutated simulations**:

| Observation | Measured value |
|---|---:|
| Core-read scoreboard checks | **1,234** |
| UVM scoreboard errors | **0** |
| Refill requests | **871** |
| Dirty writebacks | **14** |
| Completed whole-cache flushes | **2** |
| Peak memory-side outstanding refills | **32** |
| Core request stall cycles observed | **3,552** |
| Core response stall cycles observed | **125** |
| Memory request stall cycles observed | **210** |

The same-bank MSHR-full test reaches **8 outstanding refills** and stalls a ninth request. The four-bank pressure test reaches **32 aggregate outstanding refills**.

## Merged coverage

Coverage is reported for the cache RTL separately from generic Vortex infrastructure and UVM code.

| Metric | Vortex cache RTL scope |
|---|---:|
| Line | **94.6%** (87 / 92) |
| Branch | **84.7%** (461 / 544) |
| Expression | **84.1%** (1974 / 2348) |
| Toggle | **61.0%** (23779 / 38962) |

Reachable functional coverage is **100% (52 / 52 bins)**. Two raw memory-response-stall bins are classified unreachable in the current standalone configuration because the cache-side response queue keeps the external response-ready path asserted for the exercised patterns.

Toggle coverage is intentionally not presented as an overall quality score; many untouched toggles are width/state-space activity rather than missing functional scenarios.

## Historical mutation evidence

Run #81 also performs two negative-control checks against known upstream Vortex fixes.

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

Run: https://github.com/cydonia0717-crypto/l2-cache-uvm-verification/actions/runs/36678971383
