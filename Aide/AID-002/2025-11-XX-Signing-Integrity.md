# 🧱 AIDE in Motion: Automating and Signing System Integrity Checks

> *If your system could testify, AIDE would be its expert witness.*
> In this article, we take the next step — not just monitoring integrity, but **proving** it.
> With automation, cryptographic signatures, and daily verification, your Linux system learns to **trust but verify itself**.

---

## 🧰 From Watching to Proving

- Encryption is not one of my strong points.
- I understand about public and private keys have made SSH auth keys and signed them so I know some but as a whole I have never looked deep into the subject
- I wanted to take on this type of article to learn more about it and how it can help secure systems.

- In the first article, we installed and configured **AIDE** to fingerprint our Linux system — a silent watcher that notices when files change.
- If verifies section of the files system but what is verifying it?
- How could hashing and encryption protect it?

Absolutely — here’s your **updated full version** of

# 🧱 *AIDE in Motion: Automating and Signing System Integrity Checks*

integrated with the **improved signing design section**.

This version keeps the strong story arc from setup → verification → automation → proof,
but now transitions gracefully into *“Next-Gen Signing”* concepts like `minisign` and `ssh-keygen -Y sign`.

The tone stays professional, practical, and future-facing — exactly how your ProofTrail series flows.


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
We’ll use a wrapper script that runs AIDE only **after confirming the baseline’s signature** — and signs each new report with its own hash and detached GPG signature.

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

## 🔏 Phase 3 – Modernizing the Signing Process

Our setup now signs and verifies logs with GPG — and that’s solid for most Linux environments.
But if you want faster, simpler, or more portable signatures, there are a few modern alternatives worth exploring.

---

### ⚙️ Option 1 · minisign — Lightweight & Scriptable

[minisign](https://jedisct1.github.io/minisign/) provides compact Ed25519 signatures ideal for automation.

Generate a keypair once:

```bash
minisign -G -p /root/.aide/minisign.pub -s /root/.aide/minisign.key
```

Sign your log:

```bash
minisign -S -s /root/.aide/minisign.key -m aide-check.log
```

Verify:

```bash
minisign -V -p /root/.aide/minisign.pub -m aide-check.log
```

✅ **Why it’s better for automation**

* One small keypair, no GPG keyring
* Ed25519 crypto — faster and smaller
* Ideal for embedding in future ProofTrail JSON ledgers

---

### 🧮 Option 2 · SSH Key Signing

If your system already uses SSH keys, you can reuse them for signing reports:

```bash
ssh-keygen -Y sign -f /root/.ssh/id_ed25519 -n aide aide-check.log
ssh-keygen -Y verify -f /root/.ssh/id_ed25519.pub -n aide -s aide-check.log.sig -I root aide-check.log
```

✅ **Why it’s attractive**

* Uses existing infrastructure
* No new tools needed
* Supports short-lived or rotated keys
* Naturally fits Zero-Trust and ProofTrail frameworks

---

### 🧠 Option 3 · JSON-Ledger with age Encryption (ProofTrail-Ready)

A future-proof method is to record hashes and timestamps in a signed JSON ledger:

```bash
sha512sum aide-check.log > aide-check.log.sha512
date --iso-8601=seconds > aide-check.log.timestamp
```

Then store entries like:

```json
{
  "file": "aide-check-2025-10-27.log",
  "hash": "sha512:...",
  "timestamp": "2025-10-27T21:00:04Z",
  "signature": "aide-check-2025-10-27.log.sig"
}
```

This creates portable, verifiable evidence ready for blockchain-style chaining in ProofTrail.

---

## 🔗 Phase 4 – From Integrity to Evidence Chain

You’ve now transformed AIDE into something bigger:
an automated, cryptographically signed audit trail that can prove — mathematically — that no part of your system’s integrity reporting has been falsified.

| Step | Action                          | Artifact        | Purpose                       |
| ---- | ------------------------------- | --------------- | ----------------------------- |
| 1    | Verify baseline                 | aide.db.gz.sig  | Ensure trusted state          |
| 2    | Verify prior logs               | .sha512 / .sig  | Historical continuity         |
| 3    | Run AIDE                        | aide-check.log  | Capture new integrity data    |
| 4    | Hash + sign                     | .sha512 + .sig  | Proof of authenticity         |
| 5    | Optional minisign / SSH signing | .minisig / .sig | Faster, portable alternatives |

This workflow is now the foundation for **ProofTrail**, where signatures and timestamps will be chained together into a cross-system ledger.

---

## 🧭 Conclusion – Integrity You Can Prove

Most monitoring systems *tell* you something changed.
This setup *proves* those alerts can be trusted.

By combining AIDE with daily automation, detached signatures, and optional next-gen signing, your system becomes its own witness — one that can testify to its own state with mathematical certainty.

> In the next phase, we’ll go one level deeper — linking each signature into a cryptographic ledger to create a verifiable, tamper-proof **evidence chain** across systems.

---

### 📚 Related Resources

* [AIDE-001: Every File Deserves a Fingerprint – AIDE on Oracle Linux 9](https://github.com/richard-sebos/articles/blob/main/Aide/AID-001/2025-11-xx-AIDE-Overview.md)
* `man aide.conf` and `man aide`
* `man systemd.timer`
* `minisign` / `ssh-keygen -Y sign` documentation
* `gpg --help` for detached signing options

---

Would you like me to create a **visual summary diagram** (PlantUML or Markdown ASCII) showing how the *evidence chain evolves* — baseline → check → hash → signature → ledger — to embed at the end of this article or the next ProofTrail piece?
