#!/usr/bin/env python3
from pathlib import Path
import argparse, re

SB = re.compile(r'\[SB\] data_checks=(\d+) errors=(\d+) refill_reqs=(\d+) writebacks=(\d+) flush_rsp=(\d+)')
COV = re.compile(r'\[COV\] max_mem_outstanding=(\d+)')
UE = re.compile(r'UVM_ERROR\s*:\s*(\d+)')
UF = re.compile(r'UVM_FATAL\s*:\s*(\d+)')

ap=argparse.ArgumentParser()
ap.add_argument('--runs',default='out/verilator/runs')
ap.add_argument('--coverage',default='out/verilator/coverage/scope_summary.txt')
ap.add_argument('--out',default='out/verilator/coverage/regression_summary.md')
a=ap.parse_args()

rows=[]
for log in sorted(Path(a.runs).glob('*/run.log')):
    t=log.read_text(errors='ignore')
    m=SB.search(t)
    if not m: continue
    c=COV.search(t); ue=UE.findall(t); uf=UF.findall(t)
    rows.append(dict(name=log.parent.name,checks=int(m.group(1)),errors=int(m.group(2)),
                     refills=int(m.group(3)),writebacks=int(m.group(4)),flush=int(m.group(5)),
                     peak=int(c.group(1)) if c else 0,uvm_error=int(ue[-1]) if ue else -1,
                     uvm_fatal=int(uf[-1]) if uf else -1))
if not rows: raise SystemExit('no run summaries found')
ok=all(r['errors']==0 and r['uvm_error']==0 and r['uvm_fatal']==0 for r in rows)
tot=lambda k: sum(r[k] for r in rows)
o=['# Generated Regression Evidence','',
   f"- Executed simulation runs: **{len(rows)}**",
   f"- Result: **{'PASS' if ok else 'FAIL'}**",
   f"- Core read data checks: **{tot('checks')}**",
   f"- Scoreboard errors: **{tot('errors')}**",
   f"- Memory refill requests: **{tot('refills')}**",
   f"- Dirty writebacks: **{tot('writebacks')}**",
   f"- Flush completions: **{tot('flush')}**",
   f"- Peak memory-side outstanding refills: **{max(r['peak'] for r in rows)}**",
   '', '| Run | Checks | Refills | Writebacks | Flush | Peak outstanding | UVM E/F |',
   '|---|---:|---:|---:|---:|---:|---:|']
for r in rows:
    o.append(f"| `{r['name']}` | {r['checks']} | {r['refills']} | {r['writebacks']} | {r['flush']} | {r['peak']} | {r['uvm_error']}/{r['uvm_fatal']} |")
cp=Path(a.coverage)
if cp.exists(): o += ['', '## Scoped coverage', '', '```text', cp.read_text().strip(), '```']
out=Path(a.out); out.parent.mkdir(parents=True,exist_ok=True); out.write_text('\n'.join(o)+'\n')
print(out.read_text())
if not ok: raise SystemExit(1)
