# Testcase List

The current regression contains **29 unique functional/stress test classes**, plus five additional seeds of `l2_random_test`. Historical mutation tests are listed separately because they intentionally run defective RTL and are expected to trigger an assertion/checker.

| Test | Verification intent |
|---|---|
| `l2_smoke_test` | cold miss/hit, full write, partial write, readback |
| `l2_same_line_merge_test` | concurrent requests to one missing line / pending-chain behavior |
| `l2_mshr_full_test` | 9 same-bank misses against 8 bank-local MSHR entries |
| `l2_ooo_refill_test` | tagged out-of-order memory refill |
| `l2_clean_eviction_test` | 4-way same-set clean replacement without writeback |
| `l2_dirty_eviction_test` | dirty replacement and writeback data checking |
| `l2_bank_hotspot_test` | dual-port same-bank pressure and arbitration/resource stress |
| `l2_random_test` | dual-port randomized read/write/backpressure stress |
| `l2_read_hit_test` | distinguish first miss from subsequent hit |
| `l2_write_allocate_test` | write miss allocation followed by readback |
| `l2_partial_write_test` | byte-enable merge and untouched-byte preservation |
| `l2_mem_backpressure_test` | downstream memory-request backpressure |
| `l2_core_rsp_backpressure_test` | upstream core-response backpressure |
| `l2_multi_bank_test` | traffic spanning all four banks |
| `l2_mshr_reuse_test` | allocate/free/reallocate MSHR entries; require legal refill-tag reuse and no active alias |
| `l2_reset_recovery_test` | reset with four active misses; flush outstanding checker/agent state and prove fresh core-tag reuse |
| `l2_cross_port_partial_test` | concurrent P0/P1 byte-disjoint writes to same words across four banks and subsequent data readback |
| `l2_line_offsets_test` | all eight 64-bit word offsets in a 64-byte line |
| `l2_global_mshr_pressure_test` | 32 aggregate MSHRs plus 33rd-request backpressure |
| `l2_writeback_backpressure_test` | dirty eviction while memory request path is throttled |
| `l2_refill_writeback_overlap_test` | dirty writeback overlapping independent refill traffic |
| `l2_flush_test` | dirty whole-cache flush, completion and post-flush refill |
| `l2_set_slice_sweep_test` | address/set-slice functional coverage closure |
| `l2_mem_rsp_backpressure_test` | stress external response traffic; documents unreachable stall classification |
| `l2_four_way_residency_test` | prove four lines coexist in one 4-way set before replacement |
| `l2_byteen_sweep_test` | exhaustive non-zero 8-bit byte-enable patterns and readback |
| `l2_flush_pipeline_race_test` | write-hit/flush overlap; paired with flush historical mutation |
| `l2_plru_victim_test` | controlled same-set accesses and observed PLRU victim behavior |
| `l2_release_coalesce_race_test` | back-to-back same-line writes around MSHR allocate/finalize release |

## Additional random seeds

`l2_random_test` is rerun with seeds 31–35 after the main directed suite. Run #91 passed all five with zero UVM errors/fatals, together with 29 distinct tests, including reset recovery, memory-tag lifetime checks and dual-port partial writes.

## Mutation checks

- `repro_historical_flush_bug.sh` + `l2_flush_pipeline_race_test`: kills pre-a686ceec flush behavior.
- `repro_historical_mshr_release_bug.sh` + `l2_release_coalesce_race_test`: kills pre-35e85f6 release/coalesce behavior.
