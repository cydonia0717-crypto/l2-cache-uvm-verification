# Simulation Environment

## Primary industry-oriented environment

The project targets **Linux + Synopsys VCS/Verdi + UVM 1.2** for the commercial-simulator workflow.

`scripts/run_vcs.sh`:

- builds the pinned Vortex cache RTL and project UVM environment;
- supports the same selectable bank-pipeline latency used by the open-source flow;
- compiles SVA and code coverage (`line+cond+fsm+tgl+branch`);
- writes each test/seed into a separate run directory;
- reuses a compiled `simv` image unless `FORCE_REBUILD=1`;
- treats a non-zero UVM error/fatal summary as a failed run.

Single test:

```bash
./scripts/setup_vortex.sh
TEST=l2_smoke_test SEED=1 bash scripts/run_vcs.sh
```

Full VCS regression:

```bash
bash scripts/vcs_regression.sh
```

Both `scripts/vcs_regression.sh` and `scripts/oss_regression.sh` consume the same canonical test/seed list from `scripts/regression_manifest.txt`, preventing the commercial and open-source full-suite definitions from drifting apart.

The regression script executes the same 27 functional/stress tests plus five additional random seeds. If `urg` is available, it also merges the generated `simv.vdb` databases into `out/vcs/urg_report`.

VCS and Verdi are commercial licensed tools and are not bundled in this repository. The VCS scripts have been shell/static reviewed, but this public project does **not** claim a measured VCS/URG result because the ChatGPT execution environment does not contain a Synopsys license.

## Reproducible open-source CI environment

The measured public regression uses:

- Verilator/UVM open-source simulation;
- `verilator/uvm` pinned at commit `656f20d087370a7c742e00188d20bbf30fa95339`;
- Vortex pinned at commit `a4afb2351f4b4464a53779874616d95571c376d0`;
- UVM source kept close to the UVM 1.2 component/sequence/config-db style used by the VCS flow.

Bootstrap:

```bash
bash scripts/bootstrap_oss.sh
source .env.oss
TEST=l2_smoke_test SEED=1 bash scripts/run_verilator.sh
```

GitHub Actions PR qualification run #91 is the current 34-run measured baseline. It completes the functional/stress suite, additional random seeds, coverage merge and two historical-bug mutation checks.

For a local one-command open-source run after bootstrap:

```bash
source .env.oss
VERILATOR_DOCKER=0 bash scripts/oss_regression.sh
```

Or use `make regression`; `make qualification` also executes the two mutation checks.

The Verilator flow is the reproducible CI evidence path, while VCS/Verdi remains the intended commercial-simulator/debug flow.
