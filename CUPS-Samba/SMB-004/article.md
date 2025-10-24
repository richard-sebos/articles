# 🧱 Legacy 4 – *Beyond smb.conf: PAM, MAC, and auditd for Accountability*

### 🎯 Objective

Demonstrate how to integrate system-level security layers with Samba — **authentication (PAM)**, **access control (MAC)**, and **evidence collection (auditd)** — turning a hardened service into a verifiable one.

---

## 🗂️ Outline

### 1. Introduction – “The Edges of the Sandbox”

* Global and share configs secure Samba internally; PAM, MAC, and auditd secure its interactions with the OS.
* ProofTrail framing: “Verification requires visibility at every layer.”

### 2. Step 1 – PAM Integration

* Check `/etc/pam.d/samba`.
* Add login attempt restrictions:

  ```bash
  auth required pam_faillock.so deny=3 unlock_time=600
  ```
* Demonstrate lockout test.
* Show relevant log in `/var/log/secure` or `journalctl -xe`.

### 3. Step 2 – MAC Enforcement (SELinux / AppArmor)

* SELinux:

  ```bash
  getsebool -a | grep samba
  setsebool -P samba_enable_home_dirs on
  ```

* Show custom context:

  ```bash
  semanage fcontext -a -t samba_share_t "/srv/samba/finance(/.*)?"
  restorecon -Rv /srv/samba/finance
  ```

* AppArmor alternative: `aa-status`, `aa-enforce`.

* ProofTrail tie-in: *“MAC policies are machine-readable proofs of containment boundaries.”*

### 4. Step 3 – auditd Integration

* Install & enable:

  ```bash
  sudo apt install auditd
  sudo systemctl enable --now auditd
  ```
* Create audit rule for Samba access:

  ```bash
  auditctl -w /srv/samba/finance -p rwxa -k samba_finance
  ```
* Review logs:

  ```bash
  ausearch -k samba_finance
  aureport -f
  ```
* Explain how this adds *provable accountability.*

### 5. Step 4 – Correlation and Reporting

* Show how `auditd` and Samba logs confirm events.
* Map to ProofTrail’s concept of *log chaining*.

### 6. Step 5 – Automate Verification

* Mention integrating hash/signature generation of logs for later ProofTrail ingestion.
* Provide short sample script:

  ```bash
  sha256sum /var/log/audit/audit.log >> prooftrail.logchain
  ```

### 7. Lessons Learned

* System-level hardening makes logs actionable evidence.
* You can’t prevent every event — but you can **prove** what happened.

### 🧩 ProofTrail Note

> “Once your system can prove its own history, security becomes verification — not guesswork.”
