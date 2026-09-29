# Interview Notes — project explanation skeleton

## 60–90 second project introduction

I used the open-source Vortex cache RTL as the DUT and independently built a SystemVerilog/UVM verification environment around it. I configured it as a 256KB, 4-way, 64B-line, four-bank write-back L2 cache with an 8-entry MSHR per bank and two upstream request ports. The reason I chose this DUT was that it is a real non-blocking cache rather than a single-FSM teaching model, so the verification focus can go into multiple outstanding misses, MSHR allocation/release, dirty eviction, refill ordering and backpressure.

The TB has two active core agents and a reactive memory agent. The memory side can delay and reorder refill responses by tag, so I can deliberately fill all eight MSHRs in one bank, create same-line concurrent misses, or return responses in an order different from the requests. The scoreboard maintains an architectural memory image and correlates read responses by port and tag; memory writebacks are also checked byte by byte. I use functional coverage, code coverage and SVA together for closure.

## Important wording

Do not claim that the cache RTL was self-written. State clearly: **open-source RTL as DUT; vPlan, UVM environment, stimulus, checker, coverage, regression and debug were independently built.**

Do not quote a final coverage percentage until it has actually been measured.
