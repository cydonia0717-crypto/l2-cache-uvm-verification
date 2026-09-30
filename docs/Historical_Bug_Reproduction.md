# Historical flush-race mutation test

This project uses current Vortex RTL as the DUT. It does **not** claim to have discovered an upstream Vortex defect.

Vortex commit `a686ceec54c842f4b01689b01f3f6c33e1ed2fc0` fixed a real cache-flush race. Before that fix, `VX_cache_flush` could leave `STATE_WAIT1` when only `mshr_empty` was true. A request could still be resident in the bank pipeline or a committed store could still be draining while the flush walk began evicting lines. The upstream fix changed the guard to require both:

```systemverilog
if (mshr_empty && bank_empty)
```

The portfolio test `l2_flush_pipeline_race_test` creates the same risk shape:

1. warm and dirty a cache line;
2. issue another write hit;
3. immediately issue a whole-cache flush;
4. wait for flush completion;
5. read the line back from backing memory and check the newly written value.

`scripts/repro_historical_flush_bug.sh` temporarily mutates the pinned Vortex source back to the pre-fix guard:

```systemverilog
if (mshr_empty)
```

It then rebuilds a separate simulator image and runs only the targeted test. The script succeeds only when the mutant still compiles and the verification environment detects a functional/assertion failure. The source is restored automatically on exit.

This is mutation-based reproduction of a known historical upstream bug, not a claim that the student authored the RTL fix or originally found the defect.
