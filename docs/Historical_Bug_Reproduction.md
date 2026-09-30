# Historical flush-race mutation test

This project uses current Vortex RTL as the DUT. It does **not** claim to have discovered or authored the upstream defect/fix.

## Upstream defect

Vortex commit `a686ceec54c842f4b01689b01f3f6c33e1ed2fc0` fixed a cache-flush race. Before that fix, `VX_cache_flush::STATE_WAIT1` advanced to the flush walk when only `mshr_empty` was true. A request could still be in the bank pipeline, or a committed store/memory request could still be draining.

The upstream fix changed the condition from:

```systemverilog
if (mshr_empty)
```

to:

```systemverilog
if (mshr_empty && bank_empty)
```

where `bank_empty` represents quiescence of the bank pipeline and memory-request queue.

## Verification strategy

The directed test `l2_flush_pipeline_race_test` creates a tight hit-write/flush overlap. The mutation flow additionally uses a four-stage bank pipeline to widen the interval where the MSHR can be empty while bank work is still in flight.

A white-box assertion is bound to every `VX_cache_flush` instance:

```systemverilog
(state == STATE_WAIT1 && mshr_empty && !bank_empty)
|=> (state == STATE_WAIT1);
```

This checks the actual control invariant. It is more deterministic than waiting for a later architectural data mismatch, whose visibility depends on which cache line the flush walker reaches first.

## Mutation flow

`scripts/repro_historical_flush_bug.sh`:

1. verifies that the pinned RTL contains the fixed guard;
2. temporarily changes it back to `if (mshr_empty)`;
3. rebuilds a separate Verilator image with `BANK_LATENCY=4`;
4. runs `l2_flush_pipeline_race_test`;
5. requires a checker/assertion failure; a compile failure does not count;
6. restores the original source automatically.

## Measured evidence

GitHub Actions run **#81** killed the mutant. The failing mutant emitted:

```text
FLUSH_RACE: flush left WAIT1 while bank pipeline/request queue was not empty
```

The normal pinned RTL passed the same regression with zero UVM errors/fatals.

Run: https://github.com/cydonia0717-crypto/l2-cache-uvm-verification/actions/runs/36678971383
