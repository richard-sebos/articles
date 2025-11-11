#!/bin/bash
set -euo pipefail

# CONFIGURATION
AIDE_ORIG_SCRIPT="/opt/aide/aide-daily-check.sh"
SECURE_DIR="/root/.secure-aide"
ENCRYPTED_SCRIPT="$SECURE_DIR/metrics-update.sh.gpg"
WRAPPER_SRC="/usr/local/src/system-metrics-wrapper.c"
WRAPPER_BIN="/usr/local/bin/system-metrics"
SERVICE_NAME="system-metrics"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
TIMER_PATH="/etc/systemd/system/${SERVICE_NAME}.timer"

# Step 1: Move and Encrypt
echo "[+] Securing AIDE script"
mkdir -p "$SECURE_DIR"
chmod 700 "$SECURE_DIR"
cp "$AIDE_ORIG_SCRIPT" "$SECURE_DIR/metrics-update.sh"

echo "[+] Encrypting script with GPG"
gpg --batch --yes -c --output "$ENCRYPTED_SCRIPT" "$SECURE_DIR/metrics-update.sh"

# Optional: remove original or keep for maintenance
# shred -u "$SECURE_DIR/metrics-update.sh"

# Step 2: Create Innocent-Looking C Wrapper
echo "[+] Writing C wrapper"
cat > "$WRAPPER_SRC" <<EOF
#include <stdlib.h>

int main() {
    return system("gpg --quiet --batch --yes --decrypt $ENCRYPTED_SCRIPT | /bin/bash");
}
EOF

gcc "$WRAPPER_SRC" -o "$WRAPPER_BIN"
chmod 700 "$WRAPPER_BIN"
chown root:root "$WRAPPER_BIN"

# Step 3: Create Systemd Service
echo "[+] Creating systemd service: $SERVICE_PATH"
cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=Collect system performance metrics
After=network.target

[Service]
Type=oneshot
ExecStart=$WRAPPER_BIN
StandardOutput=journal
StandardError=journal
EOF

# Step 4: Create Timer
echo "[+] Creating systemd timer: $TIMER_PATH"
cat > "$TIMER_PATH" <<EOF
[Unit]
Description=Run system metrics collection daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Step 5: Reload Systemd and Start Timer
echo "[+] Enabling and starting timer"
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now "${SERVICE_NAME}.timer"

echo "[+] Done. AIDE now runs as a system metrics job."
