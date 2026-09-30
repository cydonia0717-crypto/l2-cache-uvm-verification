# Verification Debug / Mutation Report

## Purpose

This document records two high-risk cache-control defects used as **negative controls**. They are historical Vortex defects already fixed upstream; this project does not claim original discovery. The goal is to demonstrate that the verification environment can reject the defective behavior when it is deliberately restored.

## Case A — Flush leaves quiescence wait too early

### Defect class

The historical implementation allowed the flush FSM to leave WAIT1 when only the MSHR was empty:

```systemverilog
if (mshr_empty)
    state_n = STATE_FLUSH;
```

The fixed behavior also requires the bank pipeline/request path to be quiescent:

```systemverilog
if (mshr_empty && bank_empty)
    state_n = STATE_FLUSH;
```

### Why the original end-to-end test was insufficient

At bank latency 2, the interval where `mshr_empty==1` but `bank_empty==0` is narrow. A readback-only checker can miss the illegal control transition if the flush walk does not collide with the pending update in a data-visible way.

### Verification improvement

The mutation run uses bank latency 4 to widen the occupancy window and binds a white-box temporal invariant to the internal flush controller:

> If the controller is in WAIT1 while MSHR is empty but the bank is still non-quiescent, it must remain in WAIT1 on the next cycle.

### Measured result

GitHub Actions run #81 kills the mutant at time 3025:

```text
FLUSH_RACE: flush left WAIT1 while bank pipeline/request queue was not empty
```

## Case B — MSHR allocation links behind an entry being released

### Defect class

An MSHR allocation may find an existing same-line entry and link itself to that entry's pending chain. If the matched predecessor is being finalized as a hit and released in the same cycle, it will never receive a later fill/dequeue event. A younger request linked behind it can therefore be orphaned.

The upstream fix excludes same-cycle releasing entries from the match set.

### Verification improvement

The directed stress sends back-to-back same-line traffic and binds an invariant around allocation/finalize lifetime:

> A new allocation must never report a predecessor equal to an MSHR entry being released in the same cycle.

### Measured result

GitHub Actions run #81 kills the mutant at time 2885:

```text
MSHR_RELEASE_COALESCE: allocation linked behind an entry released in the same cycle
```

## Verification lesson

Both cases show why end-to-end data checking and internal assertions complement each other. The scoreboard proves architectural correctness over completed transactions; the white-box SVA catches short-lived illegal control states that may not always propagate to an externally visible mismatch in a deterministic test.
