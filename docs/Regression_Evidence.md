# Regression Evidence

This file records measured results from GitHub Actions rather than estimated resume numbers.

## Baseline green regression

GitHub Actions run **#70** (commit `d3478ba5a2add11f3cf183fe9a201115312929c4`) completed successfully on the open-source Verilator/UVM flow.

The run executed the directed cache suite plus a five-seed constrained-random regression. Across the observed tests:

- no UVM errors or fatals were reported;
- a same-bank MSHR-pressure test reached **8 simultaneous memory refills** and observed upstream request backpressure;
- global traffic reached **32 outstanding memory refills** across the four banks;
- random stress exercised both upstream ports, all four banks, memory-request backpressure and core-response backpressure;
- flush testing observed dirty writebacks and a flush completion response.

### Merged code coverage

Coverage is reported separately for the cache RTL so unrelated Vortex library/generic code does not dilute the DUT metric.

| Metric | Vortex cache RTL scope |
|---|---:|
| Line | **94.6%** (87 / 92) |
| Branch | **84.7%** (461 / 544) |
| Expression | **83.9%** (1971 / 2348) |
| Toggle | **61.0%** (23775 / 38962) |

### Functional coverage

The reachable functional coverage model reached **100% (52 / 52 bins)** in the scoped report. The raw global summary reports 52/54 because two memory-response-stall bins are intentionally classified as unreachable at this interface/configuration: the cache-side response queue keeps `mem_rsp_ready` asserted for the response patterns used by this standalone configuration.

The project therefore does **not** quote a fabricated 90%+ overall Verilator coverage number. The meaningful DUT metrics above are kept separate from generic Vortex support RTL and UVM infrastructure.

## Verification hardening

After the baseline regression was green, historical upstream Vortex cache defects were converted into mutation tests. The mutation flow deliberately reintroduces an old RTL defect and requires a directed test/checker to fail for the mutation to be considered killed.

Current mutation targets:

1. flush beginning before the bank pipeline is fully drained;
2. MSHR allocation coalescing onto an entry being released in the same cycle.

These mutation checks are intentionally stricter than the ordinary green regression and are used to improve the quality of the directed corner cases. A mutation is not counted as detected merely because compilation fails; the checker/assertion must expose a functional failure.
