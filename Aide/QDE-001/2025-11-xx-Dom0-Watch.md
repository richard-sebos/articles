# 🧱 Every File Deserves a Fingerprint – Monitoring Integrity on Dom0 with an External Baseline

> *Before dashboards, before SIEMs, there was one simple question:*
> *“Did my files change?”*

---

## 🧑‍💻 A Minimalist’s Dilemma: Security Without Bloat

As a long-time Linux user, I’ve explored many distros over the years — from mainstream ones like Ubuntu and Fedora to more niche systems. Like many, I spent time distro-hopping, chasing the ideal setup. While each distribution has its quirks (mainly around package managers), most applications behave the same across environments.

That was true until I started working with **Qubes OS**.


---

## 📚 Table of Contents

1. [🔍 Why File Integrity Still Matters](#-why-file-integrity-still-matters)
2. [🏠 Why Dom0 Requires Special Consideration](#-why-dom0-requires-special-consideration)
3. [🧪 A Self-Contained Integrity Script for Dom0](#-a-self-contained-integrity-script-for-dom0)
4. [🛠️ Example `config.conf`](#️-example-configconf)
5. [🔍 What Each Symbol Means](#-what-each-symbol-means)
6. [🧪 How the Audit Flow Works](#-how-the-audit-flow-works)
7. [✅ Sample Usage](#-sample-usage)
8. [🔒 Where Should the Baseline Live?](#-where-should-the-baseline-live)
9. [🧠 Why This Works](#-why-this-works)
10. [🧾 Command Summary](#-command-summary)
11. [🧭 Conclusion](#-conclusion)

---


Qubes challenges conventional Linux habits by embracing a philosophy of **isolation, minimization, and strict compartmentalization**. It encourages you to rethink what should run *where*, and *why*. You don’t just “install everything in one system” — you carefully decide which Qube (VM) should handle a task, and what risks that entails.

Take **AIDE** for example — a traditional Linux intrusion detection tool. It’s powerful, but installing it directly in dom0 contradicts the Qubes philosophy of minimal software and minimal trust in dom0.

So what if you still want **file integrity monitoring** — without breaking the security model?

That’s exactly what this article covers: how to replicate AIDE-like functionality **without installing anything in dom0**, using a secure streaming architecture and an isolated audit VM.


## 🏠 Why Dom0 Requires Special Consideration

In many virtualization or secure home-lab setups (like Xen or Qubes OS), the privileged domain `dom0` is extremely locked down:

* You want to minimize software installed in dom0 to reduce attack surface
* Tools like AIDE may not be appropriate inside dom0
* You may restrict network or clipboard access to/from dom0
* Storing integrity data inside dom0 can compromise trust

To solve this, we use a design where **dom0 emits trusted data**, and a **separate audit VM** stores and processes the results. The baseline lives outside dom0, where it’s more secure — and dom0 stays minimal and auditable.

---

## 🧪 A Self-Contained Integrity Script for Dom0

We use a single script called `run_integrity.sh`, which:

* Reads a `config.conf` file for target files/directories
* Scans each file, computes SHA-256 hashes and captures metadata
* Streams that data securely via `qvm-run --pass-io` to an **audit VM**
* Tells the audit VM whether to **create** a new baseline or **check** against an existing one

This keeps dom0 minimal and stateless, and places trust in an isolated, air-gapped audit VM.

---

## 🛠️ Example `config.conf`

```bash
define SIMPLE_CONTENT = p+u+g+s+m+sha256

# Monitor critical kernel-related config files
/etc/sysctl.conf$       SIMPLE_CONTENT
/etc/sysctl.d           SIMPLE_CONTENT
/etc/modprobe.d         SIMPLE_CONTENT
/etc/modules-load.d     SIMPLE_CONTENT
/etc/udev               SIMPLE_CONTENT
/etc/crypttab$          SIMPLE_CONTENT
```

---

### 🔍 What Each Symbol Means

| Symbol   | Attribute                 | What it Tracks                                     |
| -------- | ------------------------- | -------------------------------------------------- |
| `p`      | Permissions               | File mode (e.g., `644`, `755`)                     |
| `u`      | User ownership            | File owner (e.g., `root`)                          |
| `g`      | Group ownership           | File group (e.g., `wheel`, `root`)                 |
| `s`      | Size                      | File size in bytes                                 |
| `m`      | Modification time (mtime) | Last time file content was modified                |
| `sha256` | Hash of file content      | SHA‑256 hash — detects any change in file contents |

---

## 🧪 How the Audit Flow Works

Here’s the full integrity pipeline:

1. **In `dom0`**: run `run_integrity.sh` with either `create` or `check` as argument
2. **It reads config.conf**, finds files, computes SHA256 + metadata
3. **Streams data to the `audit-vm`** using `qvm-run --pass-io`
4. **In the audit VM**:

   * If `create`, saves a new trusted baseline
   * If `check`, compares to baseline and outputs a change report

---

## ✅ Sample Usage

### Create a new baseline:

```bash
./run_integrity.sh create
```

### Check against existing baseline:

```bash
./run_integrity.sh check
```

> Output will show matched and mismatched files, with a summary like:

```
==== Integrity File Check Report ====
Total files checked : 87
Files matched       : 85
Files mismatched    : 2
=====================================
```

---

## 🔒 Where Should the Baseline Live?

Your baseline should live in a hardened, network-isolated audit VM.

* No network (`qvm-prefs audit-vm netvm none`)
* No clipboard sharing or file copy
* Based on a minimal template (e.g., `fedora-minimal`)
* Store baselines as plaintext or encrypted (`gpg`)

---

## 🧠 Why This Works

This approach:

* Keeps dom0 untouched — no new packages, no file writes
* Ensures audit data is preserved in a secure vault
* Provides reliable detection of changes to critical config files
* Scales well for home labs or security-sensitive workstations

---

## 🧾 Command Summary

| Command                     | Purpose                                           |
| --------------------------- | ------------------------------------------------- |
| `./run_integrity.sh create` | Generate and store a new integrity baseline       |
| `./run_integrity.sh check`  | Compare current dom0 state to baseline            |
| `qvm-run --pass-io`         | Used internally to securely pass data to audit-vm |
| `chmod +x run_integrity.sh` | Make the script executable                        |

---

## 🧭 Conclusion

Using a streaming integrity model built around `run_integrity.sh` gives you AIDE-like functionality **without modifying dom0**.
You get file fingerprinting, a secure external baseline, and a repeatable process that tells you: **Did anything change that shouldn't have?**

It’s a lightweight but powerful way to implement file integrity checking — built for hardened environments where **trust and containment come first**.

🔗 **See the full code and walkthrough** in the []() on GitHub.

This approach draws from traditional tools like AIDE but is tailored for modern secure virtualization platforms, offering the same confidence without breaking isolation.



