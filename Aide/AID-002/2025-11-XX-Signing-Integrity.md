# 🧱 AIDE in Motion: Automating and Signing System Integrity Checks

> *If your system could testify, AIDE would be its expert witness.*
> In this article, we take the next step — not just monitoring integrity, but **proving** it.
> With automation, cryptographic signatures, and daily verification, your Linux system learns to **trust but verify itself**.

---

## 🧭 Table of Contents

1. [From Watching to Proving](#-from-watching-to-proving)
2. [Introduction](#introduction)
3. [GPG (GNU Privacy Guard)](#gpg-gnu-privacy-guard)
4. [Protecting and Signing the AIDE Baseline](#️-protecting-and-signing-the-aide-baseline)
5. [Protecting AIDE Check Results](#️-protecting-aide-check-results)
6. [Conclusion – Integrity You Can Prove](#-conclusion--integrity-you-can-prove)
7. [Related Resources](#-related-resources)

---

## 🧰 From Watching to Proving

Most administrators install AIDE to keep watch over their systems — to detect when files change, permissions shift, or unexpected binaries appear. But detection is only half the battle. To *trust* what AIDE reports, you must also verify that its baseline and results haven’t been altered. Otherwise, a compromised attacker could quietly modify both the files **and** the evidence. This article builds on the first AIDE tutorial by showing how to sign and verify AIDE’s outputs using **GPG (GNU Privacy Guard)**, creating a chain of integrity that can be trusted even in hostile environments.

---

## Introduction

I’ll be the first to admit: encryption isn’t my strongest area.

Sure, I’ve worked with public and private keys for SSH authentication and have signed keys before, so I’m not entirely new to the topic. But I hadn’t really explored how cryptography ties into system integrity — until now.

In the first article of this series, we installed and configured **AIDE (Advanced Intrusion Detection Environment)** — a silent guardian that fingerprints your Linux system and detects when files change unexpectedly. It’s an excellent tool for monitoring file integrity, but it raises an important question:

> *If AIDE verifies the integrity of your files, who verifies the integrity of AIDE?*

That’s where **hashing** and **cryptographic signing** come into play. In this article, we’ll use GPG to sign AIDE’s baseline database and check results, ensuring every integrity report can be proven genuine — even after the fact.

---

## GPG (GNU Privacy Guard)

**GPG** is a widely used encryption and signing tool that provides both **confidentiality** and **integrity verification**. In this workflow, we’ll use it to **sign** AIDE’s database and output logs, guaranteeing they haven’t been altered after creation.

GPG works with a **public/private key pair**. Your **private key** is used to sign or decrypt data, while the **public key** can be shared with others to verify those signatures.

To create a key pair, use one of the following commands:

```bash
gpg --generate-key
# or for more control:
gpg --full-generate-key
```

You’ll be prompted to provide a name, email address, and passphrase — details used to identify and protect your key. Once generated, GPG stores your keys inside the `~/.gnupg/` directory.

To confirm your key exists, run:

```bash
gpg --list-keys
```

We’ll soon use this key to sign and verify AIDE’s baseline database and reports, creating an additional layer of trust in your monitoring process.

---

## 🗝️ Protecting and Signing the AIDE Baseline

When you run:

```bash
aide --init
```

AIDE creates a **baseline database**, a snapshot of the system defined by the rules in `aide.conf`. This database represents your system’s memory — and if it’s modified, the entire trust chain collapses.

In the previous setup, AIDE saved the baseline to `/var/lib/aide/aide.db.gz`. To protect it, we’ll sign it using GPG and store the signature securely so it can be verified before each integrity check.

```bash
# Create a secure directory
sudo mkdir -p /root/.aide

# Sign the baseline with your GPG key
sudo gpg --output /root/.aide/aide.db.gz.sig --detach-sign /var/lib/aide/aide.db.gz

# Restrict access and make it immutable
sudo chmod 400 /root/.aide/aide.db.gz.sig
sudo chattr +i /root/.aide/aide.db.gz.sig
```

The `--detach-sign` flag creates a signature file without altering the original database. Before any future `aide --check` runs, you can verify that the database hasn’t changed:

```bash
sudo gpg --verify /root/.aide/aide.db.gz.sig /var/lib/aide/aide.db.gz
```

> **🔍 Note:**
> The signature is stored in `/root/.aide` instead of alongside the baseline in `/var/lib/aide/` because `/root/` is restricted to the root user. This separation prevents low-privileged processes—or an attacker who compromises them—from accessing or modifying the signature. By isolating it in a root-only directory and marking it immutable, you preserve the trust boundary even if the baseline database itself is tampered with.


---

## 🛡️ Protecting AIDE Check Results

Once your baseline is protected, the next step is to safeguard **AIDE’s check results**. When you run `aide --check`, it compares the current system to the baseline and produces a report. These reports must also be hashed and signed — otherwise, they could be edited to hide signs of intrusion.

First, generate a timestamped log file:

```bash
LOG_DIR="/var/log/aide"
DATESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="${LOG_DIR}/aide-check-${DATESTAMP}.log"

sudo mkdir -p "$LOG_DIR"
sudo aide --check >"$LOG_FILE" 2>&1
```

This creates a report such as `/var/log/aide/aide-check-2025-10-28_15-42-01.log`. To make this log tamper-evident, hash and sign it:

```bash
HASH_FILE="${LOG_FILE}.sha512"
SIG_FILE="${LOG_FILE}.sig"

sha512sum "$LOG_FILE" >"$HASH_FILE"
gpg --output "$SIG_FILE" --detach-sign "$LOG_FILE"
```

Your log directory now holds a verifiable chain of integrity reports:

```
/var/log/aide/
├── aide-check-2025-10-28_15-42-01.log
├── aide-check-2025-10-28_15-42-01.log.sha512
└── aide-check-2025-10-28_15-42-01.log.sig
```

These signatures and hashes ensure that even if logs are tampered with it will be immediately detectable.

---

### 🧪 Automating the Workflow

To streamline the process, you can create a script that:

1. Verifies the previous AIDE log.
2. Runs `aide --check` and logs the output.
3. (Optionally) Reinitializes the baseline.
4. Hashes and signs the new log file.

By automating these steps with `cron` or `systemd.timer`, your system performs daily integrity checks and maintains a cryptographically verifiable audit trail.
You can find a full example script [**here**](*insert-link-or-path*).

---

## 🧭 Conclusion – Integrity You Can Prove

AIDE doesn’t stop attacks — it *detects evidence* that one has occurred. That evidence only matters if it can be trusted. By integrating GPG signing and hashing into your AIDE workflow, you ensure that your system’s integrity checks cannot be silently altered or falsified.

This adds an important layer of assurance to your Linux environment — one that slows attackers, strengthens your audit process, and gives you verifiable proof of system integrity.

> In the next phase, we’ll take this a step further by linking signatures into a cryptographic ledger, creating a verifiable **evidence chain** across systems.

---

### 📚 Related Resources

* [AIDE-001: Every File Deserves a Fingerprint – AIDE on Oracle Linux 9](https://github.com/richard-sebos/articles/blob/main/Aide/AID-001/2025-11-xx-AIDE-Overview.md)
* `man aide.conf` and `man aide`
* `man systemd.timer`
* `gpg --help` for signing options

