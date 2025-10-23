# **Qubes Containment Audit Framework (QCAF)**

### *Software Requirements Specification v1.0*

*(Internal Design / Open-Source Contributor Edition)*

---

## 1  Purpose and Scope

The **Qubes Containment Audit Framework (QCAF)** provides a reproducible, cryptographically verifiable method for auditing isolation and network behavior in Qubes OS.
It automates data collection in Dom0, verification and reporting in a dedicated **Security Qube**, and archival in an offline **Vault Qube**.
The goal is to enable independent reproduction of every audit run and mathematical proof that collected evidence has not been modified.

Version 1.0 focuses exclusively on the **Dom0 → Security → Vault** containment pipeline.
Future releases may add anomaly detection and cross-platform collectors.

---

## 2  Intended Audience

Researchers, security engineers, and open-source contributors interested in verifiable containment auditing, reproducible forensics, or automated evidence chains for Qubes OS.

---

## 3  System Overview

```
[ Dom0 Collector ] → [ Security Qube Processor ] → [ Vault Qube Archive ]
```

| Layer             | Role                                                              | Trusted Keys     | Network |
| ----------------- | ----------------------------------------------------------------- | ---------------- | ------- |
| **Dom0**          | Collect audit data, hash & sign provenance, transmit bundles      | Signing-only     | None    |
| **Security Qube** | Verify provenance, generate reports, sign & encrypt final package | Full keypair     | None    |
| **Vault Qube**    | Verify signatures, validate hash chain, store encrypted archives  | Public keys only | None    |

All data transfers use **Qubes qrexec**; no component ever exposes data to a network interface.

---

## 4  Functional Requirements

| ID       | Requirement                                                                                                                              |
| -------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| **F-1**  | Dom0 shall execute `qubes_net_audit.sh` to collect audit data for all running qubes.                                                     |
| **F-2**  | Dom0 shall compute SHA-256 hashes of each audit file and produce a detached signature using its signing key.                             |
| **F-3**  | Dom0 shall retrieve the Security Qube’s public key from Vault before transmission.                                                       |
| **F-4**  | Dom0 shall transmit `{JSON, hash, signature, pubkey}` to the Security Qube via `qvm-run --pass-io`.                                      |
| **F-5**  | The Security Qube shall verify the Dom0 signature and hash before processing.                                                            |
| **F-6**  | On successful verification, the Security Qube shall generate a human-readable report via `generate_qubes_report.py`.                     |
| **F-7**  | The Security Qube shall create `manifest.json` containing file names, sizes, SHA-256 sums, and the previous manifest hash.               |
| **F-8**  | The Security Qube shall append a new entry to its local `prooftrail.log` using the manifest hash chain.                                  |
| **F-9**  | The Security Qube shall encrypt and sign the final package (`.tar.age` or `.tar.minisign`) using **Curve25519/age/minisign** primitives. |
| **F-10** | The Security Qube shall securely delete plaintext intermediates after encryption.                                                        |
| **F-11** | Dom0 shall retrieve the encrypted package and forward it to the Vault Qube.                                                              |
| **F-12** | The Vault Qube shall verify signatures and hash continuity before acceptance.                                                            |
| **F-13** | The Vault Qube shall append the validated hash to its own `prooftrail.log`.                                                              |
| **F-14** | The Vault Qube shall store accepted archives for ≥ 12 months in read-only storage.                                                       |
| **F-15** | All components shall log UTC timestamps for every action.                                                                                |

---

## 5  Non-Functional Requirements

| ID        | Category     | Description                                                    |
| --------- | ------------ | -------------------------------------------------------------- |
| **NFR-1** | Security     | No private key shall leave its host qube.                      |
| **NFR-2** | Integrity    | Every file is hash-verified and included in a signed manifest. |
| **NFR-3** | Availability | Audit history shall survive VM restarts.                       |
| **NFR-4** | Performance  | Standard audit completes ≤ 5 min for ≤ 10 qubes.               |
| **NFR-5** | Usability    | Commands must run unattended under a systemd timer.            |
| **NFR-6** | Transparency | All source code and cryptographic parameters are open.         |
| **NFR-7** | Portability  | Scripts must run in Bash 5 + Python 3.9+ on Qubes 4.2+.        |

---

## 6  Handling Short-Lived Qubes

Each qube executes an event-hook `/etc/qubes/events.d/vm-start` that appends

```
<ISO-timestamp>  <vmname>  started
```

to `/var/log/qubes-vm-start.log`.
The next Dom0 audit imports any entries newer than the previous run timestamp, ensuring qubes that existed for only minutes are still represented historically.

---

## 7  Data Formats

### 7.1 Manifest Example

```json
{
  "generated_at": "2025-10-23T03:42:55Z",
  "previous_manifest_hash": "0d43…",
  "files": [
    {"name": "audit.json",  "sha256": "…", "size": 12345},
    {"name": "report.txt",  "sha256": "…", "size": 6789}
  ],
  "encryption": {
    "algorithm": "age-X25519-ChaCha20-Poly1305",
    "performed_in": "security",
    "recipient": "SecProc@local"
  }
}
```

### 7.2 ProofTrail Entry

```
2025-10-23T03:42:55Z  <manifest_hash>  <prev_hash>  audit_2025-10-23.tar.age
```

---

## 8  Interfaces & Message Flow

1. **Dom0 → Security**:  `qvm-run --pass-io sec-audit 'cat > ~/inbox/audit_pkg.tar'`
2. **Security → Dom0**:  `tar cz -C ~/outbox . | cat > /dev/stdout`
3. **Dom0 → Vault**:  `qvm-run --pass-io vault 'cat > ~/audit_vault/audit_pkg.tar.age'`
4. **Vault Verification**:  `minisign -V -P <pubkey> -m manifest.json`

No qube requires networking; all traffic moves through Qubes’ inter-VM channels.

---

## 9  Security Requirements

| ID      | Requirement                                                             |
| ------- | ----------------------------------------------------------------------- |
| **S-1** | Only Dom0, Security, and Vault Qubes may participate in QCAF transfers. |
| **S-2** | Security Qube and Vault Qube must have `netvm=None`.                    |
| **S-3** | Keys use **Curve25519** for encryption and **Ed25519** for signing.     |
| **S-4** | All files deleted with `shred -u` after encryption.                     |
| **S-5** | Each ProofTrail entry references the previous hash to prevent rollback. |
| **S-6** | Clock drift between qubes must not exceed ± 2 seconds.                  |
| **S-7** | Verification must fail closed—no partial acceptance of invalid data.    |

---

## 10  Operational Requirements

* **Scheduling:** systemd timer triggers `run_full_audit_dom0.sh` daily 02:00 UTC.
* **Rotation:** keys rotated quarterly; old public keys stored in Vault.
* **Retention:** Vault keeps 12 months; quarterly offline snapshot.
* **Recovery:** restoring `prooftrail.log` + public keys re-establishes full verifiability.
* **Alerting:** failures write to Dom0 journal and optional signal qube (`qvm-run alert-sink`).

---

## 11  Glossary

| Term                  | Definition                                                                      |
| --------------------- | ------------------------------------------------------------------------------- |
| **ProofTrail**        | Append-only file of chained hashes proving continuity of all audits.            |
| **Manifest**          | Signed JSON summary of package contents and cryptographic metadata.             |
| **Qrexec**            | Qubes’ inter-VM RPC mechanism used for non-network data transfer.               |
| **Age/Minisign**      | Modern cryptographic tools using Curve25519 (encryption) and Ed25519 (signing). |
| **Containment Audit** | Verification that isolation, firewall, and routing rules behave as intended.    |

---

## 12  Future Extensions

* Integrate AI-based anomaly detection over ProofTrail deltas.
* Support non-Qubes hypervisors (Proxmox/KVM).
* Provide web-based visualization of audit chain.
* Add HMAC layer for Vault-only verification.
* Implement disposable `sec-audit-disp` template to further minimize persistence.

---

**End of Document**
*(Revision 1.0 — October 2025)*

