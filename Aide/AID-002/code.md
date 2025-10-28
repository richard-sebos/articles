
Service file: /etc/systemd/system/aide-check.service

[Unit]
Description=Run AIDE integrity check with baseline and log verification
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/aide-daily-check.sh
StandardOutput=journal
StandardError=journal

Timer file: /etc/systemd/system/aide-check.timer

[Unit]
Description=Run AIDE integrity check daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target

Enable and verify:

sudo systemctl daemon-reload
sudo systemctl enable --now aide-check.timer

Now AIDE will run automatically every day — or immediately after boot if a run was missed.

    “Once automation is in place, integrity becomes rhythm — quiet, consistent, and hard to fake.”


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

Make it executable:

sudo chmod 700 /usr/local/sbin/aide-daily-check.sh


