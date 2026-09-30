#!/usr/bin/env python3
"""Summarize Verilator coverage by meaningful source scope.

The raw Verilator summary includes UVM, wrappers and many reusable Vortex
sources.  For resume/interview reporting we keep that raw number, but also
report the executable coverage of the cache RTL directory itself.
"""
from __future__ import annotations
from collections import defaultdict
from pathlib import Path
import sys

if len(sys.argv) < 2:
    raise SystemExit("usage: coverage_scope_report.py MERGED_DAT [OUT]")

src = Path(sys.argv[1])
out = Path(sys.argv[2]) if len(sys.argv) > 2 else None

scopes = {
    "vortex_cache_rtl": lambda f: "/third_party/vortex/hw/rtl/cache/" in f,
    "project_tb_wrapper": lambda f: "/tb/" in f or f.endswith("/rtl/l2_cache_dut_wrapper.sv"),
}
stats = {name: defaultdict(lambda: [0, 0]) for name in scopes}
functional_hit = functional_total = 0
uncovered_functional: list[str] = []

for raw in src.read_text(errors="ignore").splitlines():
    if not raw.startswith("C "):
        continue
    try:
        count = int(raw.rsplit("'", 1)[1].strip())
        payload = raw.split("'", 1)[1].rsplit("'", 1)[0]
    except (ValueError, IndexError):
        continue

    fields = {}
    for part in payload.split("\x01"):
        if not part or "\x02" not in part:
            continue
        key, value = part.split("\x02", 1)
        fields[key] = value

    file_name = fields.get("f", "")
    typ = fields.get("t", "")

    for scope_name, pred in scopes.items():
        if pred(file_name) and typ in {"line", "branch", "expr", "toggle"}:
            stats[scope_name][typ][1] += 1
            if count > 0:
                stats[scope_name][typ][0] += 1

    if typ == "covergroup":
        # Illegal/ignore bins describe forbidden or out-of-scope behavior;
        # they must not be treated as closure targets.
        if fields.get("bin_type") in {"illegal", "ignore"}:
            continue
        functional_total += 1
        if count > 0:
            functional_hit += 1
        else:
            uncovered_functional.append(
                f"{fields.get('page','?')}::{fields.get('bin','?')}"
            )

lines = ["Scoped Coverage Summary:"]
for scope_name in ("vortex_cache_rtl", "project_tb_wrapper"):
    lines.append(f"  [{scope_name}]")
    for typ in ("line", "branch", "expr", "toggle"):
        hit, total = stats[scope_name][typ]
        pct = (100.0 * hit / total) if total else 0.0
        lines.append(f"    {typ:7s}: {pct:5.1f}% ({hit}/{total})")

pct = (100.0 * functional_hit / functional_total) if functional_total else 0.0
lines.append(f"  [functional_covergroup] {pct:5.1f}% ({functional_hit}/{functional_total})")
if uncovered_functional:
    lines.append("  uncovered functional bins:")
    lines.extend(f"    - {x}" for x in uncovered_functional)

report = "\n".join(lines) + "\n"
print(report, end="")
if out:
    out.write_text(report)
