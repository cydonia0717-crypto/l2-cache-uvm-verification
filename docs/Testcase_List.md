# Testcase List

The current CI baseline contains **19 passing test classes**.

| Test | Verification intent |
|---|---|
| `l2_smoke_test` | cold miss/hit, full write, partial write, readback |
| `l2_same_line_merge_test` | concurrent requests to one missing line / miss coalescing |
| `l2_mshr_full_test` | 9 same-bank misses against 8 bank-local MSHR entries |
| `l2_ooo_refill_test` | tagged out-of-order memory refill |
| `l2_clean_eviction_test` | 4-way same-set clean replacement without writeback |
| `l2_dirty_eviction_test` | dirty replacement and writeback data checking |
| `l2_bank_hotspot_test` | dual-port same-bank pressure and arbitration/resource stress |
| `l2_random_test` | dual-port randomized read/write/backpressure stress |
| `l2_read_hit_test` | distinguish first miss from subsequent hit |
| `l2_write_allocate_test` | write miss allocation followed by readback |
| `l2_partial_write_test` | byte-enable merge and untouched-byte preservation |
| `l2_mem_backpressure_test` | downstream request backpressure |
| `l2_core_rsp_backpressure_test` | upstream response backpressure |
| `l2_multi_bank_test` | traffic spanning all four banks |
| `l2_mshr_reuse_test` | allocate/free/reallocate MSHR entries across two batches |
| `l2_line_offsets_test` | all eight 64-bit word offsets in one 64-byte line |
| `l2_global_mshr_pressure_test` | 32 aggregate MSHRs (8 per bank) plus 33rd-request backpressure |
| `l2_writeback_backpressure_test` | dirty eviction while memory request path is throttled |
| `l2_refill_writeback_overlap_test` | dirty writeback overlapping independent refill traffic |

Next closure targets: explicit PLRU victim proof, exhaustive/biased byte-enable crosses, historical upstream cache-bug reproduction, longer multi-seed random regression, and merged coverage reporting.
