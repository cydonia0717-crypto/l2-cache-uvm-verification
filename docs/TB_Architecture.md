# UVM Testbench Architecture

```text
                +-------------------+
                |       Test        |
                | sequences/config  |
                +---------+---------+
                          |
              +-----------+-----------+
              |                       |
        +-----v------+          +-----v------+
        | CoreAgent0 |          | CoreAgent1 |
        | drv + mon  |          | drv + mon  |
        +-----+------+          +-----+------+
              \                       /
               \                     /
                +--------+-----------+
                         |
                 +-------v--------+
                 |   L2 Cache DUT |
                 | 4-way / 8-MSHR/bank |
                 +-------+--------+
                         |
                  +------v-------+
                  | Memory Agent |
                  | responder +  |
                  | monitor      |
                  +------+-------+
                         |
                    Memory Model

 Core monitors ---------------------> Scoreboard
 Memory monitor --------------------> Scoreboard
 Core/memory monitors --------------> Coverage
 Interfaces ------------------------> SVA
```

## Core agents

Each core agent is active. Its driver issues a request and releases the sequence item as soon as the valid/ready handshake completes, so the sequencer can generate multiple outstanding reads. Responses are observed independently by the monitor and correlated by `{port_id, tag}`.

The response-ready path can inject backpressure probabilistically.

## Memory agent

The memory responder models external DRAM at cache-line granularity. It can:

- deassert `req_ready` to create downstream request backpressure;
- return configurable read latency;
- keep multiple read responses pending;
- select a ready response in a different order to exercise tagged refill handling;
- accept writeback traffic and update the backing memory image.

## Scoreboard

The scoreboard maintains an architectural byte-addressable reference image. Core writes update that model. For each accepted core read, the expected 64-bit word is snapshotted and stored by `{port, tag}`; the actual response is checked when it arrives.

Memory-side writebacks are additionally checked byte-by-byte against the architectural image for enabled bytes. This catches corrupted dirty eviction data independently of the core response path.

## Assertions

The first assertion set checks protocol invariants observable at the DUT boundary:

- request payload must remain stable while `valid && !ready`;
- core response payload must remain stable while backpressured;
- memory request payload must remain stable while backpressured;
- memory response payload must remain stable while backpressured.
