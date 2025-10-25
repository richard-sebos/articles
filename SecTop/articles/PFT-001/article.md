# 🧩 **ProofTrail 1 — “The Quiet SIEM: When Your System Becomes Its Own Witness”**

### 🎯 Goal

Introduce local integrity checking — no enterprise SIEM, just the system verifying itself.

---

## Outline

### 1. Hook

> “You don’t need Splunk to know if your machine’s lying to you.”

### 2. Why It Matters

* Most desktops have *no visibility* into unexpected file or configuration changes.
* Integrity checks = a personal SIEM for single hosts.

### 3. Linux Walkthrough – The Baseline Witness

```bash
sudo find /etc /boot -type f -exec sha256sum {} \; > baseline.hashes
```

* Save baseline in `~/.prooftrail/`.
* Verification later:

  ```bash
  sha256sum -c baseline.hashes | grep -v 'OK$'
  ```

### 4. QubesOS Dom0 Walkthrough – Cross-Domain Witness

```bash
sudo find /rw/config /etc/qubes -type f -exec sha256sum {} \; > /home/user/.prooftrail/dom0_baseline.hashes
```

* For AppVMs:

  ```bash
  qvm-run -p work "find /etc -type f -exec sha256sum {} \;" > work_baseline.hashes
  ```
* Store all hashes centrally in Dom0 (no network exposure).

### 5. Takeaway

> “Every system can bear witness to its own integrity — start there.”

### 6. ProofTrail Teaser

> “Next, we’ll sign these baselines — turning trust into verifiable proof.”
