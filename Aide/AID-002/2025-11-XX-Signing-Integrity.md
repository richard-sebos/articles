# 🧱 AIDE in Motion: Automating and Signing System Integrity Checks

> *If your system could testify, AIDE would be its expert witness.*
> In this article, we take the next step — not just monitoring integrity, but proving it.
> With automation, cryptographic signatures, and daily verification, your Linux system learns to **trust but verify itself**.

---

## 🧰 From Watching to Proving

In the first article, we installed and configured **AIDE** to fingerprint our Linux system — a silent watcher that notices when files change.
That was useful, but it only told half the story.

What if the watcher’s memory was altered?
What if the logs that proved integrity were tampered with after the fact?

In this second part, we evolve AIDE from a watchdog into a **witness**.
We’ll automate daily checks, sign results, verify past reports, and ensure the database itself hasn’t been changed before every run.

---

## ⚙️ Phase 1 – AIDE in Motion

### 🧩 1 · Tuning the Noise: Making AIDE Useful

By default, AIDE tracks nearly everything. That’s overkill for real security.
Focus on sensitive configuration areas — the ones attackers care about.

Edit `/etc/aide.conf`:

```bash
sudo vim /etc/aide.conf
```

Keep only these key directories:

```bash
/etc    NORMAL
/boot   CONTENT_EX
/root   NORMAL
/sbin   CONTENT_EX
```

And define rule sets:

```bash
NORMAL = R+p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha512
CONTENT_EX = R+p+i+n+u+g+s+m+c+sha512
```

Re-initialize your baseline:

```bash
sudo aide --init
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
```

> “AIDE isn’t meant to watch everything — just what matters.”

---

### 🕒 2 · Automating Integrity Checks with systemd

A security process that relies on memory isn’t secure.
Let’s make AIDE run daily on its own.

**Service file:** `/etc/systemd/system/aide-check.service`

```ini
[Unit]
Description=Run AIDE integrity check with baseline and log verification
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/aide-daily-check.sh
StandardOutput=journal
StandardError=journal
```

**Timer file:** `/etc/systemd/system/aide-check.timer`

```ini
[Unit]
Description=Run AIDE integrity check daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and verify:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now aide-check.timer
```

Now AIDE will run automatically every day — or immediately after boot if a run was missed.

> “Once automation is in place, integrity becomes rhythm — quiet, consistent, and hard to fake.”

---

## 🔐 Phase 2 – AIDE as a Witness

Now it’s not just about running checks.
It’s about proving **the checks themselves** are trustworthy.

---

### 🗝️ 3 · Protecting and Signing the Baseline

Your baseline database is your system’s memory. If it changes, all trust is gone.

Lock and sign it:

```bash
sudo mkdir -p /root/.aide
sudo cp /var/lib/aide/aide.db.gz /root/.aide/aide.db.gz
gpg --output /root/.aide/aide.db.gz.sig --detach-sign /root/.aide/aide.db.gz
sudo chmod 400 /root/.aide/aide.db.gz /root/.aide/aide.db.gz.sig
```

You can verify anytime with:

```bash
sudo gpg --verify /root/.aide/aide.db.gz.sig /var/lib/aide/aide.db.gz
```

> “If an attacker can change your baseline, they can rewrite history.”

---

### 🧾 4 · Building a Self-Verifying Daily Process

Here’s where automation becomes forensic.
We’ll use a wrapper script that runs AIDE only **after confirming the baseline’s signature** — and signs each new report with its own hash and GPG signature.

Create `/usr/local/sbin/aide-daily-check.sh`:

```bash
#!/bin/bash
# aide-daily-check.sh
# Runs daily AIDE checks with baseline and historical verification.

BASELINE="/var/lib/aide/aide.db.gz"
SIG_BASE="/root/.aide/aide.db.gz.sig"
LOG_DIR="/var/log/aide"
DATESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="${LOG_DIR}/aide-check-${DATESTAMP}.log"
HASH_FILE="${LOG_FILE}.sha512"
SIG_FILE="${LOG_FILE}.sig"

mkdir -p "$LOG_DIR"

# 1️⃣ Verify baseline before running
if ! gpg --verify "$SIG_BASE" "$BASELINE" &>/dev/null; then
    echo "❌ AIDE baseline verification FAILED — possible tampering." | systemd-cat -t aide-check -p err
    exit 1
fi
echo "✅ Verified AIDE baseline signature OK." | systemd-cat -t aide-check -p info

# 2️⃣ Verify past logs for hash and signature validity
shopt -s nullglob
for OLD_LOG in "${LOG_DIR}"/aide-check-*.log; do
    OLD_HASH="${OLD_LOG}.sha512"
    OLD_SIG="${OLD_LOG}.sig"

    [[ "$OLD_LOG" == "$LOG_FILE" ]] && continue

    if [[ -f "$OLD_HASH" ]] && ! sha512sum -c "$OLD_HASH" &>/dev/null; then
        echo "⚠️ Hash mismatch for $OLD_LOG" | systemd-cat -t aide-check -p warning
    fi

    if [[ -f "$OLD_SIG" ]] && ! gpg --verify "$OLD_SIG" "$OLD_LOG" &>/dev/null; then
        echo "⚠️ Signature verification FAILED for $OLD_LOG" | systemd-cat -t aide-check -p warning
    fi
done
shopt -u nullglob

# 3️⃣ Run AIDE check
/usr/sbin/aide --check >"$LOG_FILE" 2>&1
AIDE_STATUS=$?

if [[ $AIDE_STATUS -eq 0 ]]; then
    echo "✅ AIDE integrity check passed." | systemd-cat -t aide-check -p info
else
    echo "⚠️ AIDE detected filesystem changes. See $LOG_FILE." | systemd-cat -t aide-check -p warning
fi

# 4️⃣ Create cryptographic proofs
sha512sum "$LOG_FILE" >"$HASH_FILE"
gpg --output "$SIG_FILE" --detach-sign "$LOG_FILE"

if [[ $? -eq 0 ]]; then
    echo "🧾 Signed and hashed integrity log: $LOG_FILE" | systemd-cat -t aide-check -p info
else
    echo "❌ Failed to sign AIDE log $LOG_FILE" | systemd-cat -t aide-check -p err
fi

exit 0
```

Make it executable:

```bash
sudo chmod 700 /usr/local/sbin/aide-daily-check.sh
```

This script ensures:

* The baseline’s signature is validated before AIDE runs.
* All prior logs are re-verified via `sha512sum` and GPG.
* Each new log is timestamped, hashed, and signed.

---

### 🧪 5 · Testing and Reading the Results

Run manually to test:

```bash
sudo systemctl start aide-check.service
```

Check the system journal:

```bash
journalctl -t aide-check
```

Sample output:

```
✅ Verified AIDE baseline signature OK.
✅ AIDE integrity check passed.
🧾 Signed and hashed integrity log: /var/log/aide/aide-check-2025-10-27_19-45-02.log
```

Your log directory now contains a growing chain of tamper-evident reports:

```
/var/log/aide/
├── aide-check-2025-10-27_19-45-02.log
├── aide-check-2025-10-27_19-45-02.log.sha512
└── aide-check-2025-10-27_19-45-02.log.sig
```

Each new report verifies all previous ones — building an **unbroken evidence chain**.

---

## 🔗 Phase 3 – From Integrity to Evidence Chain

You’ve now transformed AIDE into something bigger:
an automated, cryptographically signed audit trail that can prove — mathematically — that no part of your system’s integrity reporting has been falsified.

| Step | Action            | Artifact       | Purpose                    |
| ---- | ----------------- | -------------- | -------------------------- |
| 1    | Verify baseline   | aide.db.gz.sig | Ensure trusted state       |
| 2    | Verify prior logs | .sha512 / .sig | Historical continuity      |
| 3    | Run AIDE          | aide-check.log | Capture new integrity data |
| 4    | Hash + sign       | .sha512 + .sig | Proof of authenticity      |

This workflow is now the foundation of what comes next — **ProofTrail** — where we’ll chain signatures and timestamps into a ledger for cross-system verification.

---

## 🧭 Conclusion – Integrity You Can Prove

Most monitoring systems *tell* you something changed.
This setup *proves* whether those alerts themselves can be trusted.

By combining AIDE with daily automation, detached signatures, and chained verification, your system becomes its own witness — one that can testify to its own state with mathematical certainty.

> In the next phase, we’ll go one level deeper — linking each signature into a cryptographic ledger to create a verifiable, tamper-proof **evidence chain** across systems.

---

### 📚 Related Resources

* [AIDE-001: Every File Deserves a Fingerprint – AIDE on Oracle Linux 9](https://github.com/richard-sebos/articles/blob/main/Aide/AID-001/2025-11-xx-AIDE-Overview.md)
* `man aide.conf` and `man aide`
* `man systemd.timer`
* `gpg --help` for signing options

