# 🧱 Qubes Containment Audit Framework

### Automated Verification, Evidence Collection, and ProofTrail Logging for Qubes OS Environments

---

## 🔍 Purpose

Modern security teams know that compromise is inevitable; what matters is how quickly you detect and contain it.
**Qubes OS** already enforces strong compartmentalization, but administrators rarely have tooling to *prove* that isolation is intact, measurable, and auditable over time.

The **Qubes Containment Audit Framework** solves that gap.
It automates containment verification, network probing, and log collection, producing **tamper-evident audit manifests** you can trust.

---

## 🧩 Core Components

| Module                     | Role                                                                                                                            | Output                              |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- |
| `qubes_net_audit.sh`       | Orchestrates the audit: enumerates VMs, records IP/CIDR, runs optional Nmap probes, gathers logs, and compiles a JSON manifest. | `audit_<timestamp>.json`            |
| `lib/collect_logs.sh`      | Collects kernel/firewall and qrexec journal records from each VM.                                                               | Embedded in JSON as `"system_logs"` |
| `lib/run_nmap_scan.sh`     | Executes safe port scans from a chosen NetVM (e.g. `sys-net`).                                                                  | `"nmap_raw_output"`                 |
| `lib/util.sh`              | Escapes data and writes structured JSON.                                                                                        | Internal helper                     |
| `prooftrail.log`           | Ledger of every manifest’s SHA-256 hash and timestamp.                                                                          | Integrity chain                     |
| `generate_qubes_report.py` | Converts JSON into human-readable or Markdown reports.                                                                          | `report_<timestamp>.txt`            |
| `report_audit_history.py`  | Summarizes and verifies the ProofTrail ledger.                                                                                  | `history_<timestamp>.txt`           |
| `run_full_audit.sh`        | One-command runner that executes everything, verifies hashes, and stores results.                                               | Timestamped `audit_runs/` directory |

---

## 🧠 What It Does

1. **Discovers active VMs**
   Pulls every running domain from Qubes OS and extracts its network interfaces, IPs, and CIDRs.

2. **Optionally probes containment surfaces**
   Runs controlled Nmap scans from a designated NetVM to verify exposure and routing behavior.

3. **Collects forensic evidence**
   Retrieves kernel and firewall log snippets (DROP, REJECT, qrexec events) from each VM to correlate with probe activity.

4. **Generates a tamper-evident manifest**
   All data—IPs, scans, logs—are written to JSON, hashed, and appended to a ProofTrail ledger.

5. **Produces human-readable reports**
   Reports summarize open-port status, isolation posture, and recent log activity for each VM.

6. **Maintains long-term audit integrity**
   Every run is timestamped, hashed, and independently verifiable months or years later.

---

## 🧰 Typical Use-Cases

| Scenario                       | How It Helps                                                                              |
| ------------------------------ | ----------------------------------------------------------------------------------------- |
| **Baseline verification**      | Prove a fresh Qubes installation’s isolation works as expected.                           |
| **Change detection**           | Re-run audits after updates; compare manifests for unexpected network or rule changes.    |
| **Forensic readiness**         | Collect correlated logs and hashes at regular intervals to preserve evidence chains.      |
| **Red-team validation**        | Use the same framework to test containment boundaries from controlled attack simulations. |
| **Compliance & documentation** | Demonstrate measurable security posture to auditors or clients.                           |

---

## 🧾 Example Output Snapshot

```
📄 Qubes Containment Audit Report
Generated: 2025-10-22T03:42:55Z

------------------------------------------------------------
VM: sys-firewall
  Interface: eth0  IP: 10.138.22.13/32
  🔍 Nmap Summary:
     10.138.22.13: no common TCP ports open
  ✅ Contained: no open TCP ports reported.

  🧾 Recent System Logs:
     Oct 22 03:40:21 kernel: QUBES DROP IN=vif14.0 OUT=vif15.0 ...
     Oct 22 03:40:22 kernel: QUBES DROP IN=vif14.0 OUT=vif15.0 ...
  (showing last 10 lines)
```

---

## 🔒 ProofTrail Integrity Example

```
2025-10-22T03:42:55Z  a71b72c4e3f10f9c...  audit_runs/audit_2025-10-22T03-42-55Z.json
2025-10-23T04:11:07Z  b29e51ac8e6d742f...  audit_runs/audit_2025-10-23T04-11-07Z.json
```

Each entry records the manifest hash; `sha256sum -c prooftrail.log.sha256` instantly validates the entire history.

---

## 🧭 Workflow Overview

1. **Run the full audit**

   ```bash
   ./run_full_audit.sh
   ```
2. **Review results**

   * Human report: `audit_runs/run_<ts>/report_<ts>.txt`
   * JSON manifest: `audit_runs/run_<ts>/audit_<ts>.json`
3. **Verify integrity**

   ```bash
   sha256sum -c prooftrail.log.sha256
   ```
4. **View historical summary**

   ```bash
   python3 report_audit_history.py
   ```

---

## 🧩 Extensibility

* **Platform modules:** swap `lib/get_vm_list.sh` and `lib/get_vm_ips.sh` for Proxmox, KVM, or Docker to reuse the framework elsewhere.
* **Output formats:** extend `generate_qubes_report.py` for Markdown, HTML, or PDF output.
* **Cryptographic signing:** append `gpg --sign` to ProofTrail entries for identity assurance.
* **Continuous audits:** schedule `run_full_audit.sh` via cron or `systemd` for automated evidence capture.

---

## 🧠 Vision

This framework demonstrates how defensive infrastructure can become **self-auditing**:
each containment zone proves its own integrity, logs every interaction, and preserves that proof in a verifiable ledger.

Over time, it can evolve into an **AI-assisted containment monitor**—a system that not only audits but predicts and repairs isolation drift before attackers exploit it.

---

## 📜 License & Credits

Developed as part of a personal security-research project exploring practical zero-trust verification within Qubes OS.
No proprietary dependencies; all components are Bash + Python.
You are free to reuse and extend under an open-source license of your choice.

