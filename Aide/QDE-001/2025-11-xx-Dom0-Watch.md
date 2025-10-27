# 🧱 Every File Deserves a Fingerprint – Monitoring Integrity on Dom0 with an External Baseline

> *Before dashboards, before SIEMs, there was one simple question:*
> *“Did my files change?”*

---

## 🔍 Why File Integrity Still Matters

My first exposure to file change monitoring came back in the early 2000s, when someone ran a Tripwire‑style check on a desktop Linux box and stored the results off‑machine. At the time it seemed like overkill.
Fast‑forward to today: even if you run a hardened system with minimal services, the critical question remains: **has something changed without my knowledge?**
Logs are great — but they can be erased, tampered with, or simply miss silent changes (e.g., a binary replaced while still appearing “running”). A fingerprint‑based approach watches the actual files and metadata themselves.

---

## 🏠 Why Dom0 Requires Special Consideration

In many virtualization or secure home‑lab setups (for example using Xen or Qubes OS), the privileged domain `dom0` (or equivalent) is extremely locked down:

* The operator wants to minimize any software installed in dom0 (to reduce attack surface)
* Installing a full file‑integrity tool like AIDE inside dom0 might violate the minimalism/hardening goal
* Access from dom0 to external systems or network may be restricted
* Ideally, dom0’s baseline should be stored externally or in a separate “audit” VM that has **no network access**

Because of these limits, the typical “install tool + run check on dom0” model might not apply. Instead, the workflow needs to **stream file metadata out of dom0**, offload the heavy work into a separate, isolated auditor VM, and preserve integrity results there. The baseline is external to dom0, and dom0 remains minimal.

---

## 🧪 Our Alternative: Streaming, Off‑Host Baseline

Here is the custom process we’ve built to honour dom0’s constraints:

### 1. `stream_files.sh` (runs in dom0)

* Reads a configuration file (`config.conf`) that lists directories and files to monitor
* For each file found, computes SHA‐256, captures metadata (permissions, owner, size, mtime)
* Streams the output (path|hash|perms|owner|size|mtime) to stdout

### 2. `create_database.sh` (runs in the audit VM)

* Receives the streaming metadata
* Builds a “baseline database” (text format) based on the streamed data
* Saves it in the audit VM (which has no network access)

### 3. `check_baseline.sh` (runs in the audit VM)

* On each check: stream the same dom0 data, feed into this script
* The script compares the live data against the baseline, reports:

  * Number of files checked
  * Number that match the baseline
  * Number and list of files that changed or are missing

### Configuration example (`config.conf`):

```
define SIMPLE_CONTENT = p+u+g+s+m+sha256

# Monitor critical kernel‑related config files
/etc/sysctl.conf$       SIMPLE_CONTENT
/etc/sysctl.d            SIMPLE_CONTENT
/etc/modprobe.d          SIMPLE_CONTENT
/etc/modules-load.d      SIMPLE_CONTENT
/etc/udev                SIMPLE_CONTENT
/etc/crypttab$           SIMPLE_CONTENT
```

## 🔍 What Each Symbol Means

| Symbol   | Attribute                     | What it Tracks                                                     |
| -------- | ----------------------------- | ------------------------------------------------------------------ |
| `p`      | **Permissions**               | Tracks file mode (e.g., `644`, `755`)                              |
| `u`      | **User ownership**            | The user (owner) of the file (e.g., `root`)                        |
| `g`      | **Group ownership**           | The group the file belongs to (e.g., `root`, `wheel`)              |
| `s`      | **Size**                      | File size in bytes                                                 |
| `m`      | **Modification time (mtime)** | Last time the file content was modified                            |
| `sha256` | **Hash of file content**      | A SHA‑256 hash — detects even a single byte of file content change |


This config drives what `stream_files.sh` picks up (paths) and what the baseline logic expects.

---

## ✅ Why This Approach Works for Dom0

* dom0 stays minimal (no heavy packages installed)
* All hashing/metadata capture is done inside dom0 (trusted environment) with only streaming output passed on
* Audit VM is isolated (no network), stores the baseline securely
* Baseline can be signed, encrypted or kept read‑only, making tampering harder
* The process is repeatable and auditable — you have “how many files checked” and “which didn’t match” in each run

---

## 🧾 Simple Workflow Cheat Sheet

### Create Baseline

```bash
./stream_files.sh | qvm-run --pass-io audit‑vm 'bash /home/user/create_database.sh'
```

### Check Against Baseline

```bash
./stream_files.sh | qvm-run --pass-io audit‑vm 'bash /home/user/check_baseline.sh'
```

---

## 🧠 Protecting the Baseline

Since the audit VM holds your baseline, treat it like gold. Steps you should take:

* Encrypt the baseline database (e.g., GPG)
* Store separate copies offline or on removable media
* Limit clipboard/file transfers in/out of audit VM
* Never expose the audit VM to the network (NetVM = none)

---

## 🧭 Conclusion

While a tool like AIDE does exactly what you need under many conditions, when you’re running a highly hardened environment like dom0 under virtualization, the normal install‑and‑run‑on‑the‑host model doesn’t fit.
By decoupling dom0 (data source) and the audit VM (comparator), you gain the integrity visibility you want — **fingerprints for every file you include** — while preserving dom0’s minimal and locked‑down nature.
Your system can now silently ask: *“Did my files change?”* — and get a clear, numbers‑based answer.

