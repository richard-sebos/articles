#!/usr/bin/env python3
"""
report_audit_history.py — Summarize all ProofTrail entries
Lists every qubes-audit.json run and verifies its hash
"""

import os, hashlib, sys
from datetime import datetime

def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

def main():
    base = os.path.dirname(os.path.realpath(__file__))
    prooftrail = os.path.join(base, "prooftrail.log")
    if not os.path.exists(prooftrail):
        print("❌ No prooftrail.log found.")
        sys.exit(1)

    print("📜 Qubes Containment Audit History")
    print(f"Loaded from: {prooftrail}\n")

    with open(prooftrail, "r") as f:
        lines = [l.strip() for l in f if l.strip()]

    entries = []
    for line in lines:
        try:
            ts, hashv, path = line.split(maxsplit=2)
        except ValueError:
            continue
        entries.append((ts, hashv, path))

    if not entries:
        print("No valid entries found in ProofTrail.")
        sys.exit(0)

    for ts, expected, path in entries:
        abs_path = os.path.join(base, path)
        if os.path.exists(abs_path):
            actual = sha256_file(abs_path)
            status = "✅ OK" if actual == expected else "❌ HASH MISMATCH"
        else:
            actual = "-"
            status = "⚠️ MISSING FILE"
        print(f"{ts}  {status}")
        print(f"  File: {path}")
        print(f"  Hash: {expected[:16]}... {'(ok)' if status=='✅ OK' else ''}")
        print()

    print(f"Total records: {len(entries)}")
    print(f"Report generated @ {datetime.utcnow().isoformat()}Z")

if __name__ == "__main__":
    main()
