# Release Checklist

## Completed

- [x] Pin the open-source Vortex DUT revision.
- [x] Build the standalone 256 KiB / 4-way / 4-bank cache wrapper.
- [x] Build two active core-side UVM agents.
- [x] Build a reactive memory agent/model with latency, reorder and backpressure.
- [x] Implement architectural-memory scoreboard and dirty-writeback checking.
- [x] Add protocol SVA and high-risk internal invariants.
- [x] Implement 27 unique directed/stress test classes.
- [x] Add five extra constrained-random regression seeds.
- [x] Reach 8 bank-local and 32 aggregate outstanding misses.
- [x] Close 52/52 reachable functional bins.
- [x] Measure scoped cache RTL code coverage.
- [x] Reintroduce and kill two documented historical cache-control defects.
- [x] Publish measured regression evidence and debug notes.
- [x] Add resume wording, interview notes and a code-reading study guide.
- [x] Add Makefile entry points and VCS/Verdi helper scripts.

## Remaining external-environment validation

- [ ] Execute the full `scripts/vcs_regression.sh` on a Linux machine with a valid Synopsys VCS license.
- [ ] Review the merged URG report from that licensed run.
- [ ] Open at least the MSHR-full, dirty-eviction and one mutation/debug scenario interactively in Verdi.
- [ ] If desired, save a small set of local Verdi screenshots/waveform bookmarks for personal interview review; do not commit proprietary tool artifacts or licensed binaries.

## Resume-ready threshold

The project is already defensible using the public Verilator/UVM run #81. The unchecked items above are simulator/debug-tool portability validation, not missing functional closure.
