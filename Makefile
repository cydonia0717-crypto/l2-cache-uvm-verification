SHELL := /bin/bash
SIM ?= verilator
TEST ?= l2_smoke_test
SEED ?= 1
BANK_LATENCY ?= 2

.PHONY: help setup vcs-setup check smoke run regression qualification coverage vcs-smoke vcs-regression verdi clean

help:
	@echo "Targets:"
	@echo "  make setup          - bootstrap local Verilator/UVM/Vortex stack"
	@echo "  make vcs-setup      - fetch/configure pinned Vortex for VCS"
	@echo "  make check          - static project consistency checks"
	@echo "  make smoke          - run smoke on Verilator (or SIM=vcs)"
	@echo "  make run TEST=...   - run one test"
	@echo "  make regression     - run all 34 normal OSS simulations + coverage"
	@echo "  make qualification  - regression + both historical mutation checks"
	@echo "  make coverage       - merge Verilator coverage databases"
	@echo "  make vcs-smoke      - run smoke with VCS/UVM 1.2"
	@echo "  make vcs-regression - run full VCS regression and URG when available"
	@echo "  make verdi          - open VCS KDB in Verdi"
	@echo "  make clean          - remove generated output only"

setup:
	bash scripts/bootstrap_oss.sh

vcs-setup:
	bash scripts/setup_vortex.sh

check:
	python3 scripts/check_project.py

smoke:
	@if [ "$(SIM)" = "vcs" ]; then \
	  TEST=l2_smoke_test SEED=$(SEED) BANK_LATENCY=$(BANK_LATENCY) bash scripts/run_vcs.sh; \
	else \
	  test -f .env.oss || { echo "Run 'make setup' first" >&2; exit 2; }; \
	  source .env.oss; TEST=l2_smoke_test SEED=$(SEED) BANK_LATENCY=$(BANK_LATENCY) VERILATOR_DOCKER=0 bash scripts/run_verilator.sh; \
	fi

run:
	@if [ "$(SIM)" = "vcs" ]; then \
	  TEST=$(TEST) SEED=$(SEED) BANK_LATENCY=$(BANK_LATENCY) bash scripts/run_vcs.sh; \
	else \
	  test -f .env.oss || { echo "Run 'make setup' first" >&2; exit 2; }; \
	  source .env.oss; TEST=$(TEST) SEED=$(SEED) BANK_LATENCY=$(BANK_LATENCY) VERILATOR_DOCKER=0 bash scripts/run_verilator.sh; \
	fi

regression:
	@test -f .env.oss || { echo "Run 'make setup' first" >&2; exit 2; }; source .env.oss; VERILATOR_DOCKER=0 bash scripts/oss_regression.sh

qualification:
	@test -f .env.oss || { echo "Run 'make setup' first" >&2; exit 2; }; source .env.oss; VERILATOR_DOCKER=0 WITH_MUTATIONS=1 bash scripts/oss_regression.sh

coverage:
	@test -f .env.oss || { echo "Run 'make setup' first" >&2; exit 2; }; source .env.oss; bash scripts/merge_coverage.sh

vcs-smoke:
	TEST=l2_smoke_test SEED=$(SEED) BANK_LATENCY=$(BANK_LATENCY) bash scripts/run_vcs.sh

vcs-regression:
	BANK_LATENCY=$(BANK_LATENCY) bash scripts/vcs_regression.sh

verdi:
	bash scripts/open_verdi.sh

clean:
	rm -rf out .env.oss
