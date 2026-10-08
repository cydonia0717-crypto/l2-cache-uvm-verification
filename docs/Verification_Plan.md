# Verification Plan

## Verification objectives

The verification target is not merely hit/miss functionality. The main objective is to prove that the cache preserves architectural data correctness while multiple misses, refill responses, replacement, dirty writeback and backpressure overlap.

## vPlan

| ID | Feature / risk | Stimulus | Main checks | Coverage intent |
|---|---|---|---|---|
| F01 | Cold read miss | Read untouched line | one correct core response; backing memory data preserved | read + memory refill |
| F02 | Read hit | Repeat read after refill | same data; no unnecessary architectural corruption | repeated-line access |
| F03 | Write hit | Fill then write word | subsequent read returns new bytes | write/read cross |
| F04 | Write miss / allocate | Write absent line | line allocation and later readback correct | write miss |
| F05 | Partial write | Random byte enable | untouched bytes preserved | byte-enable patterns |
| F06 | Clean replacement | 5 lines into one 4-way set | victim replacement returns correct data | same-set conflict |
| F07 | Dirty eviction | Dirty 4 ways then insert 5th | writeback address/data/byte enables correct | writeback observed |
| F08 | PLRU behavior | controlled access ordering | victim consistent with PLRU implementation | replacement scenarios |
| F09 | Multiple independent misses | 2–8 different lines | each response correlated to its original tag | outstanding depth |
| F10 | MSHR full | hold 8 same-bank fills, issue 9th | 9th request backpressured until entry frees | request-stall hit |
| F11 | Same-line pending miss | two ports miss same line | no data corruption; both requests eventually complete | same-line concurrency |
| F12 | Out-of-order refill | multiple misses + memory response reorder | each refill applied to correct MSHR/line | response reorder |
| F13 | Memory request backpressure | random `req_ready=0` | request payload stable; no request loss | mem req stall |
| F14 | Core response backpressure | random `rsp_ready=0` | response payload stable; no duplicate response | core rsp stall |
| F15 | Bank conflicts | addresses mapped to same/different banks | progress and data integrity | bank/address cross |
| F16 | Simultaneous ports | both ports active | no cross-port tag/data corruption | port × op cross |
| F17 | Reset recovery | assert reset with four accepted misses still awaiting refill, then reuse core tags | aborted epoch purged; no stale response; fresh readbacks complete | reset abort/recover |
| F18 | Random stress | constrained read/write traffic | scoreboard clean over long run | aggregate closure |
| F19 | Memory refill-tag lifecycle | saturate and retire bank-local MSHRs, then reuse tags | no active-tag alias, no unknown/duplicate refill, no leaked outstanding transaction | first allocation vs post-retirement reuse |
| F20 | Cross-port same-word byte writes | dual-port writes to same cache word with disjoint low/high byte masks under refill latency and backpressure | all 16 write pairs accepted, deterministic byte-wise merged data on readback across 4 banks | both ports touched same word with disjoint masks |
| F21 | Memory-side refill payload integrity | independent physical-DRAM shadow snapshotted on MemRd; compare full 512-bit MemRsp by tag | detect line data corruption even without a dependent core read; require single-bit negative control to fail via `SB_MEM_DATA` | positive normal refill response checks + corruption negative control |

## Closure criteria

The project is considered ready for resume/interview use only after:

1. all mandatory vPlan rows have at least one passing directed test;
2. constrained-random regression is stable across multiple seeds;
3. no unexplained scoreboard or assertion failure remains;
4. functional coverage holes are classified as reachable, unreachable, or out-of-scope;
5. code coverage holes in control logic are reviewed rather than waived solely by percentage;
6. at least two high-risk control scenarios have evidence beyond a passing end-to-end test; the current baseline uses historical-bug mutation plus white-box SVA for flush quiescence and MSHR release/coalesce lifetime.

The current published coverage numbers are measured by the open-source Verilator/UVM CI flow. Do not relabel them as VCS/URG results unless a licensed VCS regression is actually executed.
