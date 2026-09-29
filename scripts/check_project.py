#!/usr/bin/env python3
from pathlib import Path
import re, sys
root=Path(__file__).resolve().parents[1]
required=[
 "rtl/l2_cache_dut_wrapper.sv","tb/l2_uvm_pkg.sv","tb/tb_top.sv",
 "docs/Verification_Plan.md","docs/TB_Architecture.md","docs/Simulation_Environment.md",
 "scripts/run_vcs.sh","scripts/run_verilator.sh","scripts/bootstrap_oss.sh",
 ".github/workflows/oss-smoke.yml"
]
missing=[p for p in required if not (root/p).exists()]
if missing:
    print("Missing:",*missing,sep="\n  "); sys.exit(1)

pkg=(root/'tb/l2_uvm_pkg.sv').read_text()
for inc in re.findall(r'`include\s+"([^"]+)"',pkg):
    if not (root/'tb'/inc).exists() and inc != 'uvm_macros.svh':
        print(f"Broken package include: {inc}"); sys.exit(1)

checks={
 'tb/l2_uvm_pkg.sv':['L2_MSHR_SIZE   = 8','L2_NUM_BANKS   = 4','L2_NUM_WAYS    = 4','L2_CACHE_BYTES = 256*1024'],
 'rtl/l2_cache_dut_wrapper.sv':['CACHE_SIZE    = 256 * 1024','NUM_BANKS     = 4','NUM_WAYS      = 4','MSHR_SIZE     = 8'],
}
for rel, needles in checks.items():
    txt=(root/rel).read_text()
    for n in needles:
        if n not in txt:
            print(f"Invariant missing in {rel}: {n}"); sys.exit(1)

for p in root.rglob('*.sv'):
    txt=re.sub(r'//.*?$|/\*.*?\*/','',p.read_text(),flags=re.M|re.S)
    pairs=[('class','endclass'),('module','endmodule'),('interface','endinterface'),('package','endpackage')]
    for a,b in pairs:
        na=len(re.findall(rf'\b{a}\b',txt)); nb=len(re.findall(rf'\b{b}\b',txt))
        if na!=nb:
            print(f"Unbalanced {a}/{b} in {p.relative_to(root)}: {na}/{nb}"); sys.exit(1)

print("Project static checks: PASS")
