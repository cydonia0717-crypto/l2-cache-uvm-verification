# Interview Notes — L2 Cache UVM project

## 60–90 second project introduction

I selected the open-source Vortex cache RTL as the DUT and independently built a SystemVerilog/UVM verification environment around it. I configured the standalone target as a 256KB, 4-way, 64-byte-line, four-bank write-back L2 with two upstream request ports and an 8-entry MSHR per bank. I chose a real non-blocking cache rather than a single-FSM teaching cache so the verification focus could be on MSHR lifetime, multiple outstanding misses, same-line dependencies, refill routing, dirty eviction, replacement and multi-layer backpressure.

The TB has two active core agents and a reactive memory agent. The memory side can delay requests and return tagged refill responses out of request order. The scoreboard keeps an architectural byte-addressed memory image, correlates core responses by port/tag and checks dirty writebacks byte by byte. I also added functional coverage and SVA, including white-box invariants for flush quiescence and MSHR release/coalesce lifetime hazards.

The current CI regression has 29 unique functional/stress tests plus five extra random seeds. The normal regression has zero UVM errors/fatals, reaches eight outstanding misses in one bank and 32 across four banks. Scoped cache-RTL coverage is 94.6% line, 84.7% branch and 84.4% expression, with 55/55 reachable functional bins hit.

## Additional closed risk areas

- **Refill tag lifecycle:** the memory-side checker tracks accepted read requests
  by memory tag, rejects an active tag being reused early, and rejects unknown
  or duplicate refill responses. The MSHR-reuse test observed 8 legal reuses.
- **Mid-flight reset recovery:** with four pending clean misses, reset aborts
  four outstanding core requests and four refills. A fresh sequence reuses
  core tags and completes four reads without stale-context errors.
- **Cross-port write contention:** both core ports update opposite byte halves
  of each same 64-bit word. The monitor saw 16 accepted pairs across four
  banks and complete readback was correct.

## Two strong debug / verification stories

### 1. Flush race mutation

A documented Vortex fix changed the flush wait condition from only `mshr_empty` to `mshr_empty && bank_empty`. An end-to-end write/readback test did not deterministically expose the old behavior because the corruption window depends on pipeline timing and flush-walk position. I therefore converted the requirement into a white-box SVA: if the controller is in WAIT1 with MSHR empty but the bank still busy, it must remain in WAIT1 on the next cycle. When I mutate the RTL back to the old guard, the assertion fires at the exact violating cycle.

### 2. MSHR release/coalesce mutation

Another documented upstream bug allowed a younger same-line request to chain behind an MSHR entry being released as a hit in the same cycle. That predecessor will never receive a fill, so the younger entry can be orphaned. I stress it with back-to-back same-line writes and assert that an allocation may never report a predecessor equal to the entry being finalized/released. Removing the upstream release-exclusion clause makes the assertion fire.

## Questions to be ready for

**Why is MSHR size 8 but you observed 32 outstanding?**  
The configuration is 8 MSHR entries **per bank** and there are four banks. Same-bank pressure saturates at eight; addresses distributed across all banks can reach 32 aggregate outstanding misses.

**How do you match out-of-order refills?**  
The memory request carries a tag derived from bank/MSHR context. The memory agent preserves that tag when returning data, while deliberately reordering response timing. The DUT routes the response back to the correct bank/MSHR; the scoreboard independently checks the final core response using the original core port/tag and expected architectural data.

**What happens to a ninth miss in one bank?**  
Once the eight bank-local MSHR entries are occupied, the bank deasserts request readiness. The ninth request must hold valid/payload stable and is accepted only after an entry is released. The directed test observes both depth eight and upstream stall cycles.

**How do you verify dirty eviction?**  
The scoreboard updates architectural memory on accepted core writes. When the cache emits a dirty line writeback, it checks address, byte enables and every enabled byte of payload against the architectural image, then the memory model commits that line to backing storage.

**Did you write the cache RTL?**  
No. The RTL is open-source Vortex. My contribution is DUT configuration/wrapper, vPlan, UVM agents/environment, reactive memory model, scoreboard, assertions, coverage, directed/random stimulus, regression infrastructure and closure/debug work.

## Wording rule

Do not claim original discovery of the two Vortex bugs. Say: **I used documented upstream historical fixes as mutation targets to prove my verification environment could detect those classes of defects.**
