# Historical MSHR release/coalesce mutation

This is a mutation reproduction of a documented Vortex defect, not a claim of original bug discovery or RTL authorship.

## Upstream defect

Vortex commit `35e85f6f7ac711f50dff3cbec84344651285d98b` fixed a same-line MSHR lifetime race.

The cache preallocates an MSHR entry before lookup resolves. On a hit, that transient entry is released during finalize. Before the upstream fix, a younger same-line allocation in the same cycle could still select that releasing entry as its predecessor. Because the older hit entry is released and will never receive a future fill/dequeue event, the younger request can become orphaned.

The fix excludes an entry being released from the same-line match set:

```systemverilog
&& ~(dequeue_fire && (dequeue_id == ...))
&& ~(finalize_valid && finalize_is_release && (finalize_id == ...))
```

## Verification strategy

`l2_release_coalesce_race_test` warms a line, drives a 24-write back-to-back same-line burst, then reads the line. This creates repeated overlap between MSHR allocation and hit finalize/release.

A white-box MSHR invariant checks the precise forbidden relation:

```systemverilog
!(allocate_fire &&
  finalize_valid && finalize_is_release &&
  allocate_pending &&
  (allocate_previd == finalize_id))
```

In other words, an allocation must never link behind an entry that is being released in the same cycle.

## Mutation flow

`scripts/repro_historical_mshr_release_bug.sh` temporarily removes the release-exclusion term from `VX_cache_mshr.sv`, rebuilds a separate simulator image and runs the directed race test. The mutation counts as detected only when the mutant compiles and the checker/assertion exposes the defect.

## Measured evidence

GitHub Actions run **#81** killed the mutant with:

```text
MSHR_RELEASE_COALESCE: allocation linked behind an entry released in the same cycle
```

The normal pinned RTL passes the same stress sequence.

Run: https://github.com/cydonia0717-crypto/l2-cache-uvm-verification/actions/runs/36678971383
