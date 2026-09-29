# Simulation Environment

## Primary sign-off environment

The project targets Linux + Synopsys VCS/Verdi for the main UVM regression and waveform-debug workflow. `scripts/run_vcs.sh` compiles with UVM 1.2 and enables line/condition/FSM/toggle/branch code coverage.

VCS and Verdi are commercial licensed tools. They are intentionally not bundled in this repository.

## Open-source bring-up environment

For reproducible public CI and basic bring-up, the project also supports:

- Verilator v5.052
- `verilator/uvm` pinned at commit `656f20d087370a7c742e00188d20bbf30fa95339`
- Vortex pinned at commit `a4afb2351f4b4464a53779874616d95571c376d0`
- UVM code is kept source-compatible with the UVM 1.2 coding style used by the VCS flow while open-source CI compiles against the Verilator-compatible UVM tree.

Bootstrap:

```bash
./scripts/bootstrap_oss.sh
source .env.oss
TEST=l2_smoke_test SEED=1 ./scripts/run_verilator.sh
```

The Verilator path is a bring-up/CI path, not a replacement for final VCS/Verdi sign-off. UVM support in Verilator is improving rapidly, so a simulator-specific limitation must be distinguished from a DUT/TB bug before changing verification intent.
