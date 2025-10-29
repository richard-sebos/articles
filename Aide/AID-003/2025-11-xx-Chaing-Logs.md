Perfect — here’s the full outline and content plan for your **next AIDE article**, complete with example commands, narrative tone, and structure that follows naturally after *AIDE in Motion*.

---

# **AIDE Ledger: Chaining System Integrity Across Time and Servers**

### *From isolated checks to a tamper-evident timeline*

> “A single signature proves a moment.
> A chain of signatures proves history.”

---

## 🧭 Table of Contents

1. Introduction – Why Link Integrity Reports
2. Creating a Local Integrity Ledger
3. Automating Ledger Updates
4. Verifying the Integrity Chain
5. Expanding to Multiple Servers
6. Conclusion – A Chain of Trust

---

## 🧰 Introduction – Why Link Integrity Reports

In the previous article, we automated and signed AIDE reports, ensuring that every integrity check could be verified as genuine.

But there’s still a gap: time.
How do we **prove continuity** between yesterday’s and today’s integrity reports?

If an attacker deleted a week’s worth of signed logs, your verification would still pass — but your *timeline* would be incomplete. That’s where a **ledger** comes in.

By linking each AIDE report through its hash, we can create a tamper-evident chain — a lightweight, cryptographic history of system integrity that grows with each check.

---

## 📜 Creating a Local Integrity Ledger

Start by creating a directory to hold your signed logs and a simple ledger file that records them.

```bash
sudo mkdir -p /var/log/aide
sudo touch /var/log/aide/ledger.txt
sudo chmod 600 /var/log/aide/ledger.txt
```

Every time AIDE runs and generates a log, we’ll hash that log and append its hash to the ledger.

Example command sequence:

```bash
LOG_DIR="/var/log/aide"
DATESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="${LOG_DIR}/aide-check-${DATESTAMP}.log"

# Run AIDE check
sudo aide --check >"$LOG_FILE" 2>&1

# Create a hash of the report
HASH_FILE="${LOG_FILE}.sha512"
sha512sum "$LOG_FILE" >"$HASH_FILE"

# Append hash to ledger
echo "$(sha512sum "$LOG_FILE" | awk '{print $1}')  $LOG_FILE" | sudo tee -a "$LOG_DIR/ledger.txt"
```

This creates an auditable record linking each AIDE report to its hash — your first step toward a verifiable integrity chain.

---

## ⚙️ Automating Ledger Updates

Now, let’s make sure this happens automatically every day.
You can use a systemd service and timer, similar to the previous article.

### `/etc/systemd/system/aide-ledger.service`

```ini
[Unit]
Description=Run daily AIDE check and update integrity ledger
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/aide-ledger-check.sh
StandardOutput=journal
StandardError=journal
```

### `/etc/systemd/system/aide-ledger.timer`

```ini
[Unit]
Description=Run daily AIDE ledger integrity check

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

Then enable it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now aide-ledger.timer
```

---

## 🧠 The Script: `/usr/local/sbin/aide-ledger-check.sh`

Here’s a full example script to automate verification, signing, and ledger chaining:

```bash
#!/bin/bash
# aide-ledger-check.sh
# Automates daily AIDE check with chained ledger and GPG verification

LOG_DIR="/var/log/aide"
LEDGER_FILE="${LOG_DIR}/ledger.txt"
DATESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="${LOG_DIR}/aide-check-${DATESTAMP}.log"
HASH_FILE="${LOG_FILE}.sha512"
SIG_FILE="${LOG_FILE}.sig"
AIDE_DB="/var/lib/aide/aide.db.gz"
AIDE_SIG="/root/.aide/aide.db.gz.sig"

# Verify the AIDE database before running checks
echo "[INFO] Verifying AIDE baseline..."
if ! gpg --quiet --verify "$AIDE_SIG" "$AIDE_DB" >/dev/null 2>&1; then
    echo "[ERROR] Baseline signature verification failed."
    exit 1
fi

# Run AIDE check and log output
echo "[INFO] Running AIDE check..."
sudo aide --check >"$LOG_FILE" 2>&1

# Hash and sign the log
sha512sum "$LOG_FILE" >"$HASH_FILE"
gpg --output "$SIG_FILE" --detach-sign "$LOG_FILE"

# Chain to ledger
LOG_HASH=$(awk '{print $1}' "$HASH_FILE")
PREV_HASH=$(tail -n 1 "$LEDGER_FILE" | awk '{print $1}')

if [ -n "$PREV_HASH" ]; then
    echo "${LOG_HASH} ${LOG_FILE} prev:${PREV_HASH}" | tee -a "$LEDGER_FILE"
else
    echo "${LOG_HASH} ${LOG_FILE}" | tee -a "$LEDGER_FILE"
fi

# Sign the ledger for tamper detection
gpg --output "${LEDGER_FILE}.sig" --detach-sign "$LEDGER_FILE"

echo "[INFO] Ledger updated and signed successfully."
```

---

## 🔎 Verifying the Integrity Chain

To verify that the entire timeline is intact:

```bash
sudo gpg --verify /var/log/aide/ledger.txt.sig /var/log/aide/ledger.txt
```

You can also confirm that every file in the ledger still matches its hash:

```bash
cd /var/log/aide
while read -r hash file _; do
    sha512sum -c <(echo "$hash  $file") || echo "[ALERT] Integrity mismatch: $file"
done < ledger.txt
```

If even one log or hash is missing, the chain breaks — making tampering visible.

---

## 🌐 Expanding to Multiple Servers

Once the local chain is working, you can federate it.

### Option 1: Secure Sync with rsync

Sync signed logs and the ledger to a central audit host:

```bash
rsync -az -e "ssh -i /root/.ssh/audit_key" /var/log/aide/ audit@audit-server:/srv/aide/
```

### Option 2: Verify Remotely

On the central server:

```bash
cd /srv/aide
find . -name "*.sig" -exec gpg --verify {} \;
```

Add cron or systemd automation to verify the chain across hosts daily.

---

## 🧭 Conclusion – A Chain of Trust

With the **AIDE Ledger**, your system doesn’t just prove it’s clean today — it proves it’s *been* clean for every day since the ledger began.
Each log links to the last, forming a cryptographic “breadcrumb trail” of system integrity.

This transforms AIDE from a simple file integrity monitor into a **forensic audit system**, capable of proving historical consistency — not just current state.

> “AIDE tells you if something changed.
> The ledger tells you *when* and *if that change was erased*.”

---

Would you like me to follow this up with **Part 4: AIDE Federation — Centralized Integrity Verification**, building a secure audit server that collects and verifies these signed ledgers across your infrastructure?
