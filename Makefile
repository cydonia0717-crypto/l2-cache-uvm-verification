SHELL := /bin/bash
SIM ?= auto
TEST ?= l2_smoke_test
SEED ?= 1
BANK_LATENCY ?= 2

.PHONY: help setup check smoke run regression coverage vcs-smoke vcs-regression verdi clean

help:
	@echo "Targets:"
	@echo "  make setup          - bootstrap open-source Verilator/UVM/Vortex stack"
	@echo "  make check          - static project consistency checks"
	@echo "  make smoke          - run l2_smoke_test with auto-selected simulator"
	@echo "  make run TEST=...   - run one test"
	@echo "  make regression     - open-source directed + random regression"
	@echo "  make coverage       - merge Verilator coverage databases"
	@echo "  make vcs-smoke      - run smoke with VCS/UVM 1.2"
	@echo "  make vcs-regression - run full VCS regression and URG when available"
	@echo "  make verdi          - open VCS KDB in Verdi"
	@echo "  make clean          - remove generated output only"

setup:
	bash scripts/bootstrap_oss.sh

check:
	python3 scripts/check_project.py

smoke:
	SIM=$(SIM) TEST=l2_smoke_test SEED=$(SEED) BANK_LATENCY=$(BANK_LATENCY) bash scripts/run.sh

run:
	SIM=$(SIM) TEST=$(TEST) SEED=$(SEED) BANK_LATENCY=$(BANK_LATENCY) bash scripts/run.sh

regression:
	bash scripts/extended_regression.sh
	bash scripts/random_multiseed.sh

coverage:
	bash scripts/merge_coverage.sh

vcs-smoke:
	TEST=l2_smoke_test SEED=$(SEED) BANK_LATENCY=$(BANK_LATENCY) bash scripts/run_vcs.sh

vcs-regression:
	BANK_LATENCY=$(BANK_LATENCY) bash scripts/vcs_regression.sh

verdi:
	bash scripts/open_verdi.sh

clean:
	rm -rf out .env.oss
