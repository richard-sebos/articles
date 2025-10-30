# **AIDE Automation Framework: From Integrity Checks to Self-Verification**

### *Modular scripting, cryptographic signing, and a tamper-evident ledger for Linux integrity management*

> *When it comes to integrity, trust isn’t a setting — it’s a habit.*
> This framework transforms AIDE from a passive checker into an active guardian, verifying its own history before trusting the present.

---

Security in IT is a funny thing.
Everyone agrees it’s important — but how much is enough?

The answer depends on the context:

* What does the server do?
* Does it store personal or sensitive data?
* Who are the stakeholders — developers, security teams, compliance auditors?

Your SOC might see things differently than your development team.
For some readers, this framework might feel excessive. For others, it might not go far enough.
That’s okay. The goal is to present a clear, modular system that can be scaled up or down based on your environment.

---
## 🧭 Table of Contents

1. Introduction — Beyond File Integrity
2. Architecture Overview
3. Modular Script Design
4. Workflow: From Baseline to Ledger
5. Cryptographic Chain of Trust
6. Operational Automation with systemd
7. Conclusion — The System That Trusts Itself

## **Recap: Where We’ve Been**

In the previous parts of this series, we:

* Installed and configured **AIDE** (Advanced Intrusion Detection Environment)
* Ran `aide --init` to create the baseline database
* Signed and encrypted that baseline to protect against tampering
* Created a `systemd` service to automate daily integrity checks with `aide --check`
* Captured and encrypted the resulting logs, then hashed them for verification

---

## **Where We’re Going: Tamper-Evident Logging with a Ledger**

The next step is to introduce a **ledger system** that tracks each AIDE log in a chained, tamper-evident manner.

Each log entry will be:

* Signed and hashed
* Added to a ledger
* Cryptographically linked to the previous entry (i.e., chained)

This makes it significantly harder for an attacker to modify or delete historical logs without detection. Think of it as a lightweight, local blockchain — purpose-built for verifying the integrity of integrity checks.

---
## How does the Ledger Work

When AIDE runs, it doesn’t just check files — it writes a *cryptographic diary* of every run.
This diary, called the **ledger**, records one line per integrity check:

```
<log_hash> <log_path> <chain_hash>
```

Each line is a link in a growing chain of trust.
Here’s how it works step-by-step:

---

### 🧱 1️⃣ The First Entry — The Foundation

When AIDE runs for the first time, there’s no previous history to build on.
So the system simply takes a SHA-512 hash of the log itself and uses that as the starting point:

```
log_hash   = SHA512(first_log)
chain_hash = SHA512(log_hash)
```

This is your **genesis block** — the trusted starting point that anchors all future runs.

---

### 🔗 2️⃣ The Second Entry — Linking to the Past

On the next run, a new log is generated, and the system already has a previous `chain_hash`.
Now the new entry blends both the fresh log and the old chain:

```
log_hash   = SHA512(second_log)
chain_hash = SHA512(log_hash + previous_chain_hash)
```

That `+` doesn’t mean arithmetic — it means the bytes of the two hashes are concatenated before hashing again.
This makes the new chain value depend on *everything that came before it*.

---

### 🧩 3️⃣ The Third (and Beyond) — History in Motion

From this point forward, every AIDE run repeats the process:

```
chain_hash_n = SHA512(log_hash_n + chain_hash_(n-1))
```

Each line contains a fingerprint of the latest integrity check **plus the entire verified past**.
If even one earlier entry were edited, all later hashes would instantly fail verification.

---

### 📚 Example

| Run | log_hash Source            | What chain_hash Protects |
| --- | -------------------------- | ------------------------ |
| 1   | aide-check-01.log          | Only the first report    |
| 2   | aide-check-02.log + chain₁ | All reports up to run 2  |
| 3   | aide-check-03.log + chain₂ | All reports up to run 3  |
| …   | …                          | …                        |

By the tenth entry, the ledger’s hash implicitly covers *every* previous report — a cumulative proof of system integrity.

---












## 🧰 Introduction — Beyond File Integrity

Most Linux administrators install AIDE to detect file changes.
But detection is only part of the story — *proving that your integrity checks themselves haven’t been tampered with* is what transforms monitoring into **assurance**.

This project takes AIDE (Advanced Intrusion Detection Environment) and wraps it with a **modular automation framework** that:

* Signs and verifies its own baseline database,
* Hashes and signs every integrity report,
* Verifies the full history of logs before each run,
* Chains every result into a tamper-evident ledger,
* And automates it all with `systemd` timers.

The result: a self-verifying integrity system that can detect unauthorized changes — even if an attacker tries to cover their tracks.

---

## 🧩 Architecture Overview

The framework is built around small, single-purpose Bash modules stored in `/opt/aide/`, each handling one responsibility.

**Core directories**

```
/opt/aide/               # Automation scripts
/var/log/aide/           # Output and ledger
├── logs/                # Daily AIDE reports
├── hashes/              # SHA512 hash files
└── sigs/                # GPG signatures
/root/.aide/             # Protected baseline and signatures
```

**Shared configuration:**
`/opt/aide/aide-vars.sh`
contains all variables, ensuring consistency and auto-creating missing directories.

---

## ⚙️ Modular Script Design

Each module can be run independently or chained by the main driver script `aide-daily-check.sh`.

| Script                      | Purpose                                                   |
| :-------------------------- | :-------------------------------------------------------- |
| **aide-vars.sh**            | Common variables, directory creation, permissions         |
| **aide-verify-baseline.sh** | Verifies AIDE database signature before use               |
| **aide-verify-history.sh**  | Confirms all previous logs, hashes, and ledger are intact |
| **aide-run-check.sh**       | Runs `aide --check` and logs results                      |
| **aide-create-hash.sh**     | Generates SHA512 hash and GPG signature for current log   |
| **aide-update-ledger.sh**   | Chains new hash into ledger and re-signs it               |
| **aide-init.sh**            | Creates or rebuilds AIDE baseline                         |
| **aide-sign-baseline.sh**   | Hashes and signs the new baseline securely                |

This modular approach makes testing, maintenance, and auditing straightforward — each script does one thing well.

---

## 🔄 Workflow: From Baseline to Ledger

A complete AIDE run now follows a strict sequence of trust:

1. **Verify AIDE baseline** (`aide-verify-baseline.sh`)
   Ensures the baseline database hasn’t been replaced or tampered with.

2. **Verify historical records** (`aide-verify-history.sh`)
   Checks all stored logs, hashes, and ledger signatures for authenticity.

3. **Run AIDE check** (`aide-run-check.sh`)
   Executes `aide --check` and records all findings to `/var/log/aide/logs/`.

4. **Sign and hash the results** (`aide-create-hash.sh`)
   Creates verifiable `.sha512` and `.sig` files for every run.

5. **Update the ledger** (`aide-update-ledger.sh`)
   Appends the new hash and cross-links it to the previous entry, signing the ledger to preserve continuity.

6. **Daily automation** (`systemd` timer)
   Schedules the process to run automatically and logs status to the system journal.

---

## 🔐 Cryptographic Chain of Trust

Every step in the workflow produces cryptographic proof:

| Artifact               | Protection                                    |
| ---------------------- | --------------------------------------------- |
| **AIDE baseline**      | Signed with GPG and locked with `chattr +i`   |
| **Daily logs**         | Individually hashed (SHA512) and signed       |
| **Ledger**             | Chain-linked hashes, signed after each update |
| **Verification phase** | Ensures all prior proofs remain valid         |

This creates a **tamper-evident timeline**: even if an attacker gained root access and deleted logs, any missing link in the chain would be immediately detected.

---

## 🧱 Operational Automation with `systemd`

Two simple unit files complete the automation:

### `/etc/systemd/system/aide-daily-check.service`

```ini
[Unit]
Description=Run daily AIDE integrity check and ledger update
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/aide/aide-daily-check.sh
StandardOutput=journal
StandardError=journal
```

### `/etc/systemd/system/aide-daily-check.timer`

```ini
[Unit]
Description=Schedule AIDE daily integrity check

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

Enable with:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now aide-daily-check.timer
```

---

## 🧭 Conclusion — The System That Trusts Itself

With this framework in place, your Linux host doesn’t just detect changes — it proves, cryptographically, that its own integrity checks are authentic.
Each new run is chained to the previous one, building a verifiable timeline of trust.

> “If AIDE is the witness, this framework is the court reporter — recording every statement, verifying every signature, and never forgetting what was said.”

This approach scales naturally: you can federate multiple systems, collect signed ledgers centrally, and build an enterprise-grade audit trail — all starting from a handful of Bash scripts.

---

### 🧩 Related Articles in the Series

1. **AIDE on Oracle Linux 9: Every File Deserves a Fingerprint**
2. **AIDE in Motion: Automating and Signing System Integrity Checks**
3. **AIDE Ledger: Chaining System Integrity Across Time and Servers**
4. **AIDE Automation Framework: From Integrity Checks to Self-Verification** *(this article)*
