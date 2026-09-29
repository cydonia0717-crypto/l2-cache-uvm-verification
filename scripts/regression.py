#!/usr/bin/env python3
import argparse, csv, os, re, subprocess, time
from pathlib import Path

DEFAULT_TESTS = [
    "l2_smoke_test",
    "l2_mshr_full_test",
    "l2_ooo_refill_test",
    "l2_same_line_merge_test",
    "l2_dirty_eviction_test",
    "l2_random_test",
]

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--tests", nargs="*", default=DEFAULT_TESTS)
    ap.add_argument("--seeds", type=int, default=3)
    ap.add_argument("--out", default="regression_out")
    args=ap.parse_args()
    root=Path(__file__).resolve().parents[1]
    out=root/args.out; out.mkdir(exist_ok=True)
    rows=[]
    for test in args.tests:
        for seed in range(1,args.seeds+1):
            log=out/f"{test}.{seed}.log"
            env=os.environ.copy(); env.update(TEST=test,SEED=str(seed))
            t0=time.time()
            with log.open("w") as f:
                p=subprocess.run([str(root/"scripts/run_vcs.sh")],cwd=out,env=env,stdout=f,stderr=subprocess.STDOUT)
            text=log.read_text(errors="ignore")
            errs=sum(map(int,re.findall(r"UVM_ERROR\s*:\s*(\d+)",text[-4000:]))) if "UVM_ERROR" in text else 0
            fatals=sum(map(int,re.findall(r"UVM_FATAL\s*:\s*(\d+)",text[-4000:]))) if "UVM_FATAL" in text else 0
            status="PASS" if p.returncode==0 and errs==0 and fatals==0 else "FAIL"
            rows.append([test,seed,status,round(time.time()-t0,2),p.returncode])
            print(rows[-1])
    with (out/"summary.csv").open("w",newline="") as f:
        csv.writer(f).writerows([["test","seed","status","seconds","returncode"],*rows])

if __name__=="__main__": main()
