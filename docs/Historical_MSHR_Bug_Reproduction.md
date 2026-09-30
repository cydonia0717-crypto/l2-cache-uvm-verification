# Historical MSHR release/coalesce mutation

Vortex commit `35e85f6f7ac711f50dff3cbec84344651285d98b` fixed a same-line MSHR race.

The MSHR allocates an entry before the cache lookup resolves. On a cache hit, that transient entry is released during finalize. A new request to the same line can allocate in the same cycle that the older hit is being released. Before the upstream fix, the allocator could still treat the releasing entry as a valid same-line predecessor and chain the new request behind it. Because a hit entry is released and never receives a future memory fill, the new request could become orphaned and wait forever.

The fixed address-match condition excludes both a dequeued entry and an entry being released that cycle:

```systemverilog
&& ~(dequeue_fire && (dequeue_id == ...))
&& ~(finalize_valid && finalize_is_release && (finalize_id == ...))
```

The directed test `l2_release_coalesce_race_test` first warms one cache line, then launches a back-to-back burst of reads to that resident line. This creates adjacent-cycle MSHR allocate/finalize activity without requiring another memory refill.

`scripts/repro_historical_mshr_release_bug.sh` temporarily removes the release-exclusion clause, rebuilds a separate simulator image and runs the directed test. It only reports success when the mutant compiles but the verification environment catches the resulting loss of forward progress/checker failure.

This is reproduction by mutation of a documented historical upstream defect; it is not a claim of original bug discovery or RTL authorship.
