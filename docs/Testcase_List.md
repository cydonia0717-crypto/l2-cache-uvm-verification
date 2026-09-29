# Testcase List

Implemented first-wave tests:

| Test | Purpose |
|---|---|
| `l2_smoke_test` | read miss/hit, full write, partial write and readback |
| `l2_mshr_full_test` | delay memory response and drive 9 same-bank misses against an 8-entry bank-local MSHR |
| `l2_ooo_refill_test` | dual-port misses with randomized out-of-order memory responses |
| `l2_same_line_merge_test` | two ports read different words in one missing line |
| `l2_dirty_eviction_test` | dirty five lines mapping to one 4-way set and force eviction |
| `l2_random_test` | dual-port randomized stress with request/response backpressure |

Planned closure tests: clean eviction, explicit PLRU victim proof, all byte-enable shapes, bank hot-spot, refill/writeback overlap, reset during idle, reset with outstanding traffic (only if DUT contract defines it), long-latency stress, repeated MSHR allocate/free, writeback backpressure, and targeted coverage-hole tests.
