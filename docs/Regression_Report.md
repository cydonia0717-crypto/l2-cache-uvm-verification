# Regression Report

## Verified baseline

- GitHub Actions workflow: `oss-smoke`, run **#45**
- Commit: `8b792835bb304aab55b0aab94d0524ca64c62856`
- Open-source simulator flow: Verilator + UVM + pinned Vortex RTL
- Result: **19 / 19 tests PASS**
- UVM summary across every test: **0 UVM_ERROR, 0 UVM_FATAL**
- Total core read data checks: **283**
- Total observed memory refill requests: **259**
- Total observed dirty writebacks: **5**
- Peak observed memory-side outstanding refills: **32**

Run: https://github.com/cydonia0717-crypto/l2-cache-uvm-verification/actions/runs/36600528526

The numbers below are taken from the actual CI log. They are regression observations, not invented project targets.

| Test | Main verified observation |
|---|---|
| `l2_smoke_test` | 4 data checks, 2 refills, 0 errors |
| `l2_same_line_merge_test` | 2 requests on one missing line, 1 refill, same-line pending observed |
| `l2_mshr_full_test` | peak 8 outstanding in one-bank pressure scenario; upstream stall observed |
| `l2_ooo_refill_test` | 8 data checks; out-of-order refill observed |
| `l2_clean_eviction_test` | 5 refills, 0 writebacks |
| `l2_dirty_eviction_test` | 5 refills, 2 dirty writebacks |
| `l2_bank_hotspot_test` | 24 data checks, peak 8 outstanding, memory backpressure observed |
| `l2_random_test` | 128 data checks, 102 refills, 1 writeback, peak 22 outstanding |
| `l2_read_hit_test` | 2 reads, exactly 1 refill |
| `l2_write_allocate_test` | write miss + readback, exactly 1 refill |
| `l2_partial_write_test` | partial byte-enable update preserved untouched bytes |
| `l2_mem_backpressure_test` | 12 data checks, 50 memory-request stall cycles observed |
| `l2_core_rsp_backpressure_test` | 12 data checks, 35 core-response stall cycles observed |
| `l2_multi_bank_test` | all 4 banks observed, peak 4 concurrent refills |
| `l2_mshr_reuse_test` | two batches complete, 16 data checks / 16 refills |
| `l2_line_offsets_test` | all 8 words in one line complete from one refill |
| `l2_global_mshr_pressure_test` | **32** aggregate outstanding refills observed; 33rd request sees backpressure |
| `l2_writeback_backpressure_test` | dirty writeback completes under memory request backpressure |
| `l2_refill_writeback_overlap_test` | refill/writeback overlap: 17 refills, 1 writeback, peak 13 outstanding |

## What this proves

The current baseline demonstrates data integrity and forward progress across basic hit/miss behavior, same-line miss coalescing, bank-local MSHR exhaustion, aggregate four-bank MSHR pressure, dirty replacement, tagged out-of-order refill, request/response backpressure, MSHR reuse and concurrent refill/writeback activity.

It does **not** by itself prove complete cache correctness. Remaining closure work includes explicit PLRU victim checking, broader byte-enable crosses, historical-bug reproduction/mutation testing, merged code-coverage analysis and longer multi-seed random regression.
