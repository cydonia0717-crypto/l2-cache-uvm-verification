# Regression Report

## Current verified baseline

- GitHub Actions workflow: `oss-smoke`, run **#81**
- Commit: `03d0b8f6984e9e1a64a12873bf30d3d3ab07d281`
- Result: **PASS**
- 27 unique functional/stress tests + 5 extra random seeds
- 32 unmutated simulations with **0 UVM_ERROR / 0 UVM_FATAL**
- 1,234 core-read data checks
- 871 refill requests
- 14 dirty writebacks
- peak **32** simultaneous memory-side refills

Run: https://github.com/cydonia0717-crypto/l2-cache-uvm-verification/actions/runs/36678971383

## Directed test evidence

| Test | Measured observation |
|---|---|
| `l2_smoke_test` | 4 data checks, 2 refills |
| `l2_same_line_merge_test` | 2 reads share one refill; same-line pending observed |
| `l2_mshr_full_test` | peak 8 same-bank refills; 84 upstream stall cycles |
| `l2_ooo_refill_test` | 8 data checks; out-of-order refill observed |
| `l2_clean_eviction_test` | 5 refills, 0 writebacks |
| `l2_dirty_eviction_test` | 5 refills, 2 writebacks |
| `l2_bank_hotspot_test` | 24 checks; 196 core-request stalls; memory-request stalls observed |
| `l2_random_test` seed 8 | 128 checks; 102 refills; peak 22 outstanding |
| `l2_read_hit_test` | two reads, exactly one refill |
| `l2_write_allocate_test` | write-miss allocation + readback, one refill |
| `l2_partial_write_test` | partial-byte update preserves untouched bytes |
| `l2_mem_backpressure_test` | 12 checks; 50 memory-request stall cycles |
| `l2_core_rsp_backpressure_test` | 12 checks; 35 response-stall cycles |
| `l2_multi_bank_test` | all four banks observed |
| `l2_mshr_reuse_test` | 16 checks / 16 refills across reuse batches |
| `l2_line_offsets_test` | all eight words served from one refill |
| `l2_global_mshr_pressure_test` | **32** outstanding refills; 33rd request backpressured |
| `l2_writeback_backpressure_test` | dirty writeback under downstream throttle |
| `l2_refill_writeback_overlap_test` | 17 refills + 1 writeback; peak 13 outstanding |
| `l2_flush_test` | 4 dirty writebacks; flush completion; 4 post-flush read checks |
| `l2_set_slice_sweep_test` | 16 checks spanning set-slice bins |
| `l2_mem_rsp_backpressure_test` | 32 checks; confirms current response-stall bins are unreachable |
| `l2_four_way_residency_test` | four same-set lines resident before replacement |
| `l2_byteen_sweep_test` | 256 read checks after exhaustive non-zero byte-enable sweep |
| `l2_flush_pipeline_race_test` | normal RTL: 2 checks, 1 writeback, one flush completion |
| `l2_plru_victim_test` | controlled replacement: 6 refills, 2 writebacks |
| `l2_release_coalesce_race_test` | 24 same-line writes + post-contention read complete with no extra refill |

Five additional random seeds (31–35) also pass. Their peak outstanding depths are 20–22 and each observes request/response/memory backpressure.

## Coverage

Vortex cache RTL scoped merged coverage:

- line: **94.6%**
- branch: **84.7%**
- expression: **84.1%**
- toggle: **61.0%**
- reachable functional bins: **52/52 = 100%**

## Negative-control / mutation evidence

The regression temporarily reintroduces two documented Vortex historical defects and requires the verification environment to reject them.

- pre-a686ceec flush guard is killed by `a_wait_for_bank_quiescent`;
- pre-35e85f6 MSHR matcher is killed by `a_no_coalesce_onto_releasing_entry`.

Both mutation steps **PASS** in run #81, meaning the defective RTL compiled and the verification environment detected the intended control violation.
