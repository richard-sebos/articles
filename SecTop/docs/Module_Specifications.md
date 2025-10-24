 Qubes Containment Audit Framework (QCAF)

### Module Specification Document (MSD) v1.0

*(Internal Engineering Draft — October 2025)*

---

## 1. Overview

The **QCAF** system is composed of modular components that interact via **Qubes qrexec** channels across three primary domains:

1. **Dom0 (Collector)**
2. **Security Qube (Processor)**
3. **Vault Qube (Verifier & Archive)**

Each domain hosts one or more modules, defined below.
Modules are designed for **isolation, testability, and deterministic reproducibility**.

---

## 2. Module Summary Table

| Domain        | Module        | Primary Function                                                        |
| ------------- | ------------- | ----------------------------------------------------------------------- |
| Dom0          | `collector`   | Runs audits, computes hashes, signs provenance                          |
| Dom0          | `transmitter` | Sends data to Security Qube and receives encrypted package              |
| Security Qube | `verifier`    | Validates Dom0 signature and hash                                       |
| Security Qube | `reporter`    | Generates human-readable report                                         |
| Security Qube | `packager`    | Creates manifest, encrypts, and signs bundle                            |
| Security Qube | `prooftrail`  | Maintains internal hash chain of processed runs                         |
| Vault Qube    | `validator`   | Verifies manifest signature and hash continuity                         |
| Vault Qube    | `archiver`    | Stores encrypted packages and ProofTrail in long-term immutable storage |
| Shared        | `crypto_lib`  | Unified cryptographic wrapper for minisign/age/sha256                   |
| Shared        | `schema_lib`  | Defines manifest, prooftrail, and log JSON schemas                      |

---

## 3. Module Specifications

---

### 3.1 Module: `collector` (Dom0)

**Purpose:**
Collect system and network audit data from Qubes, produce canonical JSON output, compute hashes, and create detached signature.

**Interfaces:**

* **Input:** N/A (triggered manually or via timer)
* **Output:**

  * `audit_<timestamp>.json`
  * `audit_<timestamp>.json.sha256`
  * `audit_<timestamp>.json.sig`

**Functional Requirements:**

1. F1.1 Collect all running qube names, network interfaces, and IPs.
2. F1.2 For each qube, run nmap probes (via sys-net).
3. F1.3 Generate JSON describing results.
4. F1.4 Compute SHA-256 hash of JSON file.
5. F1.5 Sign the hash using Dom0 signing key (minisign).
6. F1.6 Return non-zero exit on failure to generate or sign output.

**Non-Functional Requirements:**

* NFR1.1 Must not invoke Python or unverified binaries.
* NFR1.2 Execute under 3 minutes for ≤10 qubes.
* NFR1.3 Logs redact local MAC addresses before signing.

**Dependencies:**
`bash`, `sha256sum`, `minisign`, `qvm-run`, `nmap`.

---

### 3.2 Module: `transmitter` (Dom0)

**Purpose:**
Transfer audit data from Dom0 to Security Qube and handle retrieval of processed package.

**Interfaces:**

* **Input:** Signed JSON bundle from `collector`.
* **Output:** Raw encrypted `.tar.age` package for Vault.

**Functional Requirements:**

1. F2.1 Use `qvm-run --pass-io` to send files to `sec-audit:~/inbox/`.
2. F2.2 Wait for `sec-audit` to produce `~/outbox/audit_<timestamp>.tar.age`.
3. F2.3 Retrieve via stdout, store locally, and forward to Vault.
4. F2.4 Handle error signaling from Security Qube (nonzero exit code).

**Non-Functional Requirements:**

* NFR2.1 Must not modify or read decrypted data.
* NFR2.2 Runs under restricted Dom0 script path only.
* NFR2.3 Communication limited to specific RPC policy entries.

---

### 3.3 Module: `verifier` (Security Qube)

**Purpose:**
Authenticate and validate data provenance from Dom0.

**Interfaces:**

* **Input:** Audit JSON, hash, and detached signature.
* **Output:** Verified JSON and internal validation log.

**Functional Requirements:**

1. F3.1 Verify detached minisign signature from Dom0.
2. F3.2 Recalculate SHA-256 and confirm match.
3. F3.3 Write `verification.log` with UTC timestamp and results.
4. F3.4 Abort downstream processing on mismatch.

**Non-Functional Requirements:**

* NFR3.1 No network access (`netvm=None`).
* NFR3.2 Verification must complete within 10 seconds per file.
* NFR3.3 Log output must be signed and stored locally for audit.

**Dependencies:**
`minisign`, `sha256sum`, `bash`.

---

### 3.4 Module: `reporter` (Security Qube)

**Purpose:**
Transform validated audit JSON into human-readable and machine-parsable summary.

**Interfaces:**

* **Input:** Verified `audit_<timestamp>.json`.
* **Output:** `report_<timestamp>.txt` and optional `report_<timestamp>.json`.

**Functional Requirements:**

1. F4.1 Parse JSON into tabular and narrative summaries.
2. F4.2 Detect anomalies (duplicate IPs, missing firewall logs, repeated failures).
3. F4.3 Output readable report with clear sectioning (Header, Findings, Stats).
4. F4.4 Log execution time and report generation hash.

**Non-Functional Requirements:**

* NFR4.1 Report generator implemented in Python3 (no network libs).
* NFR4.2 Run within 2 minutes for ≤50 entries.
* NFR4.3 Consistent deterministic output (no random ordering).

**Dependencies:**
`python3`, `json`, `tabulate` (optional).

---

### 3.5 Module: `packager` (Security Qube)

**Purpose:**
Bundle verified and reported data, create manifest, encrypt and sign the package.

**Interfaces:**

* **Input:** JSON, report, verification logs.
* **Output:** `audit_<timestamp>.tar.age`, `manifest.json`, `manifest.sig`.

**Functional Requirements:**

1. F5.1 Generate `manifest.json` listing all included files, sizes, and SHA-256.
2. F5.2 Sign manifest with `minisign`.
3. F5.3 Encrypt tarball with Vault’s public key using `age`.
4. F5.4 Append manifest hash to ProofTrail via `prooftrail` module.
5. F5.5 Shred plaintext after encryption.

**Non-Functional Requirements:**

* NFR5.1 Must not write unencrypted data to `/home` after encryption.
* NFR5.2 Encryption must use Curve25519 key exchange, ChaCha20-Poly1305 cipher.
* NFR5.3 Encryption time ≤ 1 minute for ≤10 MB data.

---

### 3.6 Module: `prooftrail` (Security Qube)

**Purpose:**
Maintain tamper-evident hash chain of all processed audit packages.

**Interfaces:**

* **Input:** Manifest hash and timestamp.
* **Output:** Updated `prooftrail.log`.

**Functional Requirements:**

1. F6.1 Compute hash of new manifest and previous ProofTrail entry.
2. F6.2 Append new line: `<timestamp> <manifest_hash> <prev_hash> <filename>`.
3. F6.3 Sign updated ProofTrail with Security key.
4. F6.4 Verify file integrity at next startup.

**Non-Functional Requirements:**

* NFR6.1 File must remain append-only (enforce with immutable attribute).
* NFR6.2 Entry addition ≤ 2 seconds.
* NFR6.3 ProofTrail signing key stored in isolated keyring.

---

### 3.7 Module: `validator` (Vault Qube)

**Purpose:**
Verify incoming encrypted packages, manifest signatures, and hash continuity.

**Interfaces:**

* **Input:** Encrypted tarball from Dom0.
* **Output:** Verification log and updated ProofTrail.

**Functional Requirements:**

1. F7.1 Decrypt package with Vault private key.
2. F7.2 Verify manifest signature using Security public key.
3. F7.3 Validate file hashes inside manifest.
4. F7.4 Check hash continuity against previous ProofTrail entry.
5. F7.5 Re-sign ProofTrail and mark verified.

**Non-Functional Requirements:**

* NFR7.1 Vault must have no network interface.
* NFR7.2 Verification logs timestamped and signed.
* NFR7.3 Only append operations allowed to archive directory.

---

### 3.8 Module: `archiver` (Vault Qube)

**Purpose:**
Store encrypted audit artifacts and ProofTrail in immutable long-term storage.

**Interfaces:**

* **Input:** Verified `.tar.age` package and updated ProofTrail.
* **Output:** Archived copy, optional backup image.

**Functional Requirements:**

1. F8.1 Move verified packages to `/srv/audit_archive/<year>/<month>/`.
2. F8.2 Compute SHA-256 of each stored package and compare to manifest.
3. F8.3 Mark directory immutable after rotation.
4. F8.4 Create optional `.age`-encrypted tarball snapshot monthly.

**Non-Functional Requirements:**

* NFR8.1 File retention ≥ 12 months.
* NFR8.2 Monthly rotation and signature verification ≤ 15 min.
* NFR8.3 Access limited to `vault` group only.

---

### 3.9 Module: `crypto_lib` (Shared)

**Purpose:**
Provide consistent cryptographic primitives for signing, verifying, hashing, and encrypting.

**Functions:**

* `sign_file(file, key)`
* `verify_signature(file, sig, pubkey)`
* `encrypt_age(file, recipient)`
* `decrypt_age(file, key)`
* `sha256sum(file)`

**Non-Functional Requirements:**

* NFR9.1 Implemented as standalone Bash functions or Python CLI wrappers.
* NFR9.2 Must support offline operation.
* NFR9.3 Return exit code 0/1 only; no partial success states.

---

### 3.10 Module: `schema_lib` (Shared)

**Purpose:**
Define data structure standards and JSON schemas for validation.

**Files:**

* `manifest_schema.json`
* `prooftrail_schema.json`
* `report_schema.json`

**Functional Requirements:**

1. F10.1 Validate structure of JSON files before signing.
2. F10.2 Ensure presence of required keys (`timestamp`, `files`, `sha256`).
3. F10.3 Reject malformed or missing entries.

**Non-Functional Requirements:**

* NFR10.1 Implemented using lightweight JSON Schema v4 validator.
* NFR10.2 Must not modify validated files.
* NFR10.3 Versioned independently of audit scripts.

---

## 4. Module Interactions (Execution Flow Summary)

1. **Dom0**
   → `collector` → `transmitter` → (qrexec) →
2. **Security Qube**
   → `verifier` → `reporter` → `packager` → `prooftrail` → (qrexec) →
3. **Vault Qube**
   → `validator` → `archiver`.

All cryptographic and schema validation steps use the shared `crypto_lib` and `schema_lib`.

---

## 5. Open Design Notes

* The **Dom0** modules are shell-only for safety; no Python or external dependencies.
* The **Security Qube** modules may be containerized into a disposable VM for each run.
* **Vault** runs entirely offline — consider a periodic verification task to ensure integrity of stored ProofTrail.
* Logs for every module are signed and timestamped.
* Each module exposes a `--self-test` flag that runs input/output verification and checksum validation.

---

## 6. Module-Level Deliverables

| Module                                      | Primary Language   | Deliverable                                        |
| ------------------------------------------- | ------------------ | -------------------------------------------------- |
| collector / transmitter                     | Bash               | `/usr/local/bin/run_full_audit_dom0.sh`            |
| verifier / reporter / packager / prooftrail | Bash + Python      | `/home/user/process_audit.sh` and Python utilities |
| validator / archiver                        | Bash               | `/home/user/vault_verify.sh`                       |
| crypto_lib / schema_lib                     | Bash + JSON Schema | `/usr/local/lib/qcaf/`                             |

---

## 7. Traceability Matrix

| Requirement ID (from SRS) | Implemented In Module(s)     |
| ------------------------- | ---------------------------- |
| F-1 – F-5                 | collector                    |
| F-6 – F-10                | verifier, reporter, packager |
| F-11 – F-14               | validator, archiver          |
| S-1 – S-7                 | crypto_lib, prooftrail       |
| NFR-1 – NFR-7             | all modules                  |
| 6. Short-lived Qubes      | collector                    |

---

## 8. Revision Notes

**Version:** 1.0
**Date:** October 2025
**Author:** The Million Dollar Architect
**Status:** Draft for internal engineering review.
