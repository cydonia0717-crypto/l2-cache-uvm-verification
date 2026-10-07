#!/usr/bin/env python3
from pathlib import Path
import re, sys
root=Path(__file__).resolve().parents[1]
required=[
 "rtl/l2_cache_dut_wrapper.sv","tb/l2_uvm_pkg.sv","tb/tb_top.sv",
 "docs/Verification_Plan.md","docs/TB_Architecture.md","docs/Simulation_Environment.md",
 "scripts/run_vcs.sh","scripts/run_verilator.sh","scripts/bootstrap_oss.sh",
 "scripts/oss_regression.sh","scripts/regression_manifest.txt","Makefile",
 ".github/workflows/oss-smoke.yml"
]
missing=[p for p in required if not (root/p).exists()]
if missing:
    print("Missing:",*missing,sep="\n  "); sys.exit(1)

pkg=(root/'tb/l2_uvm_pkg.sv').read_text()
for inc in re.findall(r'`include\s+"([^"]+)"',pkg):
    if not (root/'tb'/inc).exists() and inc != 'uvm_macros.svh':
        print(f"Broken package include: {inc}"); sys.exit(1)

# Project invariants that must stay synchronized with DUT configuration.
checks={
 'tb/l2_uvm_pkg.sv':['L2_MSHR_SIZE   = 8','L2_NUM_BANKS   = 4','L2_NUM_WAYS    = 4','L2_CACHE_BYTES = 256*1024'],
 'rtl/l2_cache_dut_wrapper.sv':['CACHE_SIZE    = 256 * 1024','NUM_BANKS     = 4','NUM_WAYS      = 4','MSHR_SIZE     = 8'],
}
for rel, needles in checks.items():
    txt=(root/rel).read_text()
    for n in needles:
        if n not in txt:
            print(f"Invariant missing in {rel}: {n}"); sys.exit(1)

# Regression manifest sanity: one canonical list must describe the measured 32-run suite.
manifest_lines=[
    ln.strip() for ln in (root/'scripts/regression_manifest.txt').read_text().splitlines()
    if ln.strip() and not ln.lstrip().startswith('#')
]
if len(manifest_lines) != 32:
    print(f"Expected 32 normal regression entries, found {len(manifest_lines)}"); sys.exit(1)

test_names=[]
for spec in manifest_lines:
    m=re.fullmatch(r'(l2_[A-Za-z0-9_]+_test):(\d+)',spec)
    if not m:
        print(f"Malformed regression entry: {spec}"); sys.exit(1)
    name=m.group(1)
    test_names.append(name)
    path=root/'tb'/'tests'/f'{name}.sv'
    if not path.exists():
        print(f"Regression test source missing: {path.relative_to(root)}"); sys.exit(1)
    inc=f'`include "tests/{name}.sv"'
    if inc not in pkg:
        print(f"Regression test not registered in tb/l2_uvm_pkg.sv: {name}"); sys.exit(1)

if len(set(test_names)) != 27:
    print(f"Expected 27 unique regression test classes, found {len(set(test_names))}"); sys.exit(1)

# Basic structure sanity: every SV source should have balanced class/module/interface/package pairs.
for p in root.rglob('*.sv'):
    txt=re.sub(r'//.*?$|/\*.*?\*/','',p.read_text(),flags=re.M|re.S)
    pairs=[('class','endclass'),('module','endmodule'),('interface','endinterface'),('package','endpackage')]
    for a,b in pairs:
        na=len(re.findall(rf'\b{a}\b',txt)); nb=len(re.findall(rf'\b{b}\b',txt))
        if na!=nb:
            print(f"Unbalanced {a}/{b} in {p.relative_to(root)}: {na}/{nb}"); sys.exit(1)

print("Project static checks: PASS")
