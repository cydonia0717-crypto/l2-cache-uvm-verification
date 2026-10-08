# Coverage Plan and Closure Status

The coverage strategy separates **architectural/transaction coverage**, **stateful concurrency coverage**, **assertion coverage**, and **RTL code coverage**. Stimulus intent is not sampled directly; observations come from accepted/completed interface activity and monitor history.

## Functional coverage model

Covered categories include:

- core request, response, request-stall and response-stall events;
- port 0 / port 1 and read/write operation;
- cache-line word-offset classes;
- address/set slices and all four banks;
- refill vs dirty writeback;
- outstanding refill depth including 8-entry same-bank saturation and 32-entry aggregate pressure;
- same-line pending requests;
- in-order vs out-of-order refill completion;
- memory-request backpressure;
- core-response backpressure;
- selected crosses such as port × operation;
- first-use and legal re-use of retired refill tags;
- observed same-word writes from both core ports with nonoverlapping byte masks.

Measured reachable closure in run #91: **55 / 55 bins = 100%**.

Two raw `mem_rsp_stall` bins are classified unreachable for the current standalone cache/memory-interface configuration: the external response-ready path remains asserted for the exercised response traffic because of the internal response queue. They are retained in the model as documentation but excluded from the reachable-bin denominator.

## Independent memory response data oracle

The scoreboard maintains a **physical DRAM mirror** distinct from the latest
core-visible architectural memory model. It updates the DRAM mirror only on
accepted memory-side writebacks, takes a 512-bit snapshot when each refill read
request is accepted, and checks the full returned line using the corresponding
memory tag. A one-bit corruption injected in the reactive memory model must
produce `SB_MEM_DATA` and fail the qualification stage. This mutation is a
deliberate checker negative control, not an upstream RTL defect.

## Assertions

Boundary SVA checks request/response payload stability while stalled and memory-request line alignment.

Two white-box invariants target high-risk lifetime/control behavior:

- flush cannot leave WAIT1 while `mshr_empty && !bank_empty`;
- a new MSHR allocation cannot link behind an entry being finalized/released in the same cycle.

Both invariants have been proven useful by killing historical Vortex bug mutations in run #91.

## Code coverage

Merged Verilator coverage for the **Vortex cache RTL scope** in run #91:

| Metric | Result |
|---|---:|
| Line | **94.6%** (87 / 92) |
| Branch | **84.7%** (461 / 544) |
| Expression | **84.4%** (1982 / 2348) |
| Toggle | **61.2%** (23851 / 38962) |

Code coverage holes are reviewed by control relevance rather than closed by random stimulus solely to inflate a percentage. Generic Vortex library code and UVM infrastructure are reported separately and are not mixed into the DUT metric.

## Closure rule

A feature is considered closed only when its directed/random scenario passes, the associated checker/assertion remains clean, the intended functional bin is hit or classified, and relevant code-coverage holes have been reviewed.
