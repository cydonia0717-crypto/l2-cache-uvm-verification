# DUT Architecture — Vortex-based Non-blocking L2 Cache

## Scope

This project verifies a stand-alone instance of the Apache-2.0 Vortex cache RTL pinned at commit `a4afb2351f4b4464a53779874616d95571c376d0`.

The verification wrapper configures the cache as:

- 256 KiB capacity
- 4-way set associative
- 64-byte cache line / memory transaction granule
- 4 banks
- 2 upstream request ports
- 64-bit word access
- 8-entry MSHR per bank
- write-back, write-allocate
- pseudo-LRU replacement
- one memory-side request/response port
- single clock domain

## Data flow

Upstream requests enter through two independent valid/ready ports. The cache decodes the word address, selects a bank, performs tag/data lookup, and either returns a hit or allocates/tracks a miss in the MSHR. A miss generates a 64-byte memory read. The memory response carries an internal tag that identifies the bank/MSHR context so responses can return independently of request order.

A dirty victim produces a 64-byte writeback request before/relevant to replacement/refill completion. Multiple misses may coexist until MSHRs are exhausted; once the resource limit is reached, upstream traffic must be backpressured without losing or duplicating requests.

## Verification focus

The project intentionally focuses on non-blocking cache control correctness rather than CPU ISA behavior or cache-coherence protocols. MESI/CHI/ACE are out of scope for the first version.
