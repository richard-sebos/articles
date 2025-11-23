---
title: AIDE - File Integrity Monitoring for System Security
subtitle: Implement Silent File Verification with AIDE to Detect Unauthorized Changes Before Attackers Cover Their Tracks
date: 2025-11-23 10:00 +0000
categories: [Linux, Security]
tags: [AIDE, OracleLinux, FileIntegrity, IntrusionDetection, LinuxAdmin, Security, Monitoring]
image:
  path: /assets/img/aide_banner.png
  alt: AIDE file integrity monitoring system with cryptographic fingerprinting on Oracle Linux 9
---

> *Before dashboards, before SIEMs, there was one simple question:*
> *“Did my files change?”*
> AIDE still answers that — silently and faithfully.

---


## 🔍 Why File Integrity Still Matters

My first exposure to the idea of file intrusion detection came in the early 2000s, when a coworker installed an open-source version of **Tripwire**. He used it to scan a Linux system he kept under his desk, storing the results on a read-only flash drive. At the time, it seemed like overkill.

Fast forward to today, and **host-based intrusion detection** tools are a fundamental part of maintaining system integrity. While many administrators lean on logs for signs of intrusion, there's a deeper layer of security in tracking actual **file changes**. After all, if you want to catch an attacker changing your configuration or binaries, you need a tool that notices silent alterations—not just noisy events.

---

## 📚 Table of Contents

1. [🔍 Why File Integrity Still Matters](#-why-file-integrity-still-matters)
2. [🪵 Log Files as Intrusion Detection](#-log-files-as-intrusion-detection)
3. [🛡️ What is AIDE?](#-what-is-aide)
4. [⚙️ Installing AIDE](#️-installing-aide)
5. [🧩 Initializing the Baseline](#-initializing-the-baseline)
6. [🔎 Verifying File Integrity](#-verifying-file-integrity)
7. [🧪 Testing AIDE Detection](#-testing-aide-detection)
8. [🧠 Protecting the Baseline](#-protecting-the-baseline)
9. [🧭 Conclusion](#-conclusion)

---
## 🪵 Log Files as Intrusion Detection

Linux is excellent at logging system activity, but not all file changes are captured clearly or completely. Tools like `auditd` can monitor file operations, but in practice, they often generate false positives or miss subtle manipulations.

While enterprise environments benefit from sophisticated log aggregation and SIEM tools, what about those of us running Linux on a personal laptop, workstation, or in a home lab?

Logs can be deleted or tampered with by attackers. However, **file fingerprints don’t lie**—which is where AIDE comes in.

---

## 🛡️ What is AIDE?

**AIDE** (Advanced Intrusion Detection Environment) is a simple yet powerful tool that captures a **snapshot of your file system metadata** and cryptographic hashes. It serves as a digital fingerprint for your files and directories.

Upon initialization, AIDE creates a compressed, read-only database that contains hashes and metadata of the directories defined in its configuration. This database becomes the **baseline**, used in future comparisons to detect any unauthorized or unexpected file changes.

If a file is added, removed, or altered, AIDE will detect the discrepancy when you run a check. It’s a low-noise, high-confidence tool that offers visibility where logs might fail.

---

## ⚙️ Installing AIDE

AIDE is included in the default repositories of most major Linux distributions. On Oracle Linux 9 (and other Fedora/RHEL-based systems), installation is straightforward:

```bash
sudo dnf update -y
sudo dnf install aide -y
```

During installation, two important components are created:

* The configuration file at:
  `/etc/aide.conf`

* The working directory where baseline data is stored:
  `/var/lib/aide/`

The configuration file defines what paths and file types AIDE should monitor, while the working directory holds the actual hash database.

---

## 🧩 Initializing the Baseline

Before AIDE can begin monitoring, you must create the initial **baseline**. This is a snapshot of the current file system state.

To initialize:

```bash
sudo aide --init
```

This creates a new database at:

```bash
/var/lib/aide/aide.db.new.gz
```

To activate it, move the newly created file to replace the official baseline:

```bash
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
```

The resulting `aide.db.gz` now holds the reference hashes AIDE will use for future integrity checks.

---

## 🔎 Verifying File Integrity

Once your baseline is in place, you can verify the integrity of your system at any time with:

```bash
sudo aide --check | less
```

Typical output might look like:

```bash
Start timestamp: 2025-10-25 17:36:40 -0600 (AIDE 0.16)
AIDE found NO differences between database and filesystem. Looks okay!!

Number of entries:    66624
```

Your system will likely report a different number of entries, but if there are no changes detected, you’re good. Any additions, deletions, or modifications will be highlighted.

---

## 🧪 Testing AIDE Detection

To see AIDE in action, let’s introduce a harmless file change:

```bash
sudo touch /etc/testfingerprint
```

Now rerun the integrity check:

```bash
sudo aide --check
```

Sample output:

```
AIDE found differences between database and filesystem!!

Summary:
  Total number of entries:	66625
  Added entries:		1
  Removed entries:		0
  Changed entries:		0

---------------------------------------------------
Added entries:
---------------------------------------------------

f++++++++++++++++: /etc/testfingerprint
```

As expected, AIDE caught the new file. To acknowledge the change and update the baseline, run:

```bash
sudo aide --update
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
```

---

## 🧠 Protecting the Baseline

Your AIDE database (`aide.db.gz`) is your **trusted witness**. If it’s compromised, the integrity of all future checks is suspect. Always copy the baseline to a **secure, read-only** or encrypted location:

```bash
sudo cp /var/lib/aide/aide.db.gz /mnt/secure/aide.db.gz
```

Consider storing it on removable media, or syncing it to an encrypted vault that only root can access.

---

## 🧭 Conclusion

For this guide, I configured AIDE to monitor `/etc` and select configuration directories—areas where most critical settings live. I intentionally left out `/usr` and similar directories, as system updates can cause legitimate and frequent changes there.

While AIDE won’t stop an attacker from getting in, it gives you visibility into whether key system files have been tampered with. Think of it as part of your **defense-in-depth** strategy: not a silver bullet, but another layer that may cause a would-be intruder to move on to an easier target.

By setting up AIDE, you’ve empowered your Linux system to silently monitor its own integrity—every file, fingerprinted and verified.

## 🧾 AIDE Command Cheat Sheet

### 📦 Install AIDE

```bash
sudo dnf install aide -y
```

### ⚙️ Initialize the Baseline

Create the initial AIDE database:

```bash
sudo aide --init
```

Move the new baseline to make it official:

```bash
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
```

---

### 🔎 Check System Integrity

Compare current system state to the baseline:

```bash
sudo aide --check
```

(Optional: view output one page at a time)

```bash
sudo aide --check | less
```

---

### 🔄 Update Baseline After Approved Changes

Re-scan system and generate a new database:

```bash
sudo aide --update
```

Promote the new baseline:

```bash
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
```

---

### 🛡️ Backup the Baseline (Highly Recommended)

Copy the database to a secure location:

```bash
sudo cp /var/lib/aide/aide.db.gz /mnt/secure/aide.db.gz
```

---

### 🛠️ Key Configuration and File Paths

| File/Directory   | Purpose                                          |
| ---------------- | ------------------------------------------------ |
| `/etc/aide.conf` | AIDE configuration file                          |
| `/var/lib/aide/` | Working directory for AIDE database              |
| `aide.db.gz`     | Active baseline database                         |
| `aide.db.new.gz` | New database generated by `--init` or `--update` |
