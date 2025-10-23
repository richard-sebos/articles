#!/usr/bin/env python3
"""
generate_qubes_report.py — Human-readable containment audit report
(v2.1 - fixes \n rendering in logs)
"""

import json, re, sys
from datetime import datetime

def parse_nmap_summary(nmap_raw: str):
    """Extracts scanning summary lines from nmap_raw_output."""
    if not nmap_raw:
        return []
    summaries = []
    for line in nmap_raw.splitlines():
        line = line.strip()
        if line.startswith("Scanning"):
            target = line.replace("Scanning ", "").replace("...", "")
        elif "no common tcp ports open" in line.lower():
            summaries.append((target, "no common TCP ports open"))
        elif re.match(r"^\d+/tcp\s+\w+", line):
            m = re.match(r"^(\d+/tcp)\s+(\S+)\s+(\S+)", line)
            if m:
                summaries.append((target, f"{m.group(1)} {m.group(2)} {m.group(3)}"))
    return summaries


def make_report(data: dict) -> str:
    ts = data.get("generated_at", datetime.utcnow().isoformat())
    qubes = data.get("qubes", [])
    out = []
    out.append("📄 Qubes Containment Audit Report")
    out.append(f"Generated: {ts}")
    out.append("")

    for vm in qubes:
        name = vm["name"]
        out.append("-" * 60)
        out.append(f"VM: {name}")

        # Interfaces
        ifaces = vm.get("interfaces", [])
        if not ifaces:
            out.append("  (no interfaces detected)")
        for iface in ifaces:
            out.append(f"  Interface: {iface['interface']}")
            out.append(f"  IP:        {iface['ip']}/{iface['cidr']}")
        out.append("")

        # Nmap
        nmap_raw = vm.get("nmap_raw_output")
        summaries = parse_nmap_summary(nmap_raw) if nmap_raw else []
        out.append("  🔍 Nmap Summary:")
        if not summaries:
            out.append("     (no nmap data)")
        else:
            for target, msg in summaries:
                out.append(f"     {target}: {msg}")
        out.append("")

        # Exposure check
        has_open = any(re.search(r"\d+/tcp\s+open", s[1]) for s in summaries)
        exposure = (
            "⚠️  Review: at least one open TCP port detected."
            if has_open else
            "✅  Contained: no open TCP ports reported."
        )
        out.append(f"  {exposure}\n")

        # System logs
        logs = vm.get("system_logs")
        if logs:
            # Decode literal \n into real newlines
            logs = logs.replace("\\n", "\n").replace("\\t", "\t")
            log_lines = logs.splitlines()
            sample = log_lines[-10:] if len(log_lines) > 10 else log_lines
            out.append("  🧾 Recent System Logs:")
            for l in sample:
                out.append("     " + l)
            if len(log_lines) > 10:
                out.append("  (showing last 10 lines)\n")
            else:
                out.append("")
        else:
            out.append("  (no system logs collected)\n")

    out.append("-" * 60)
    out.append(f"Audit complete. {len(qubes)} VMs scanned.")
    return "\n".join(out)


def main():
    if len(sys.argv) < 2:
        print("Usage: generate_qubes_report.py <qubes-audit.json> [report.txt]")
        sys.exit(1)

    infile = sys.argv[1]
    outfile = sys.argv[2] if len(sys.argv) > 2 else None

    with open(infile, "r") as f:
        data = json.load(f)

    report = make_report(data)

    if outfile:
        with open(outfile, "w") as f:
            f.write(report)
        print(f"✅ Report written to {outfile}")
    else:
        print(report)


if __name__ == "__main__":
    main()
