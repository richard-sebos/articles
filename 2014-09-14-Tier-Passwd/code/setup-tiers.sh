#!/usr/bin/env bash
set -euo pipefail

### ======= CONFIGURE HERE ======= ###
PROFILE="two-tier-policy"
GROUP_APP="app_users"
GROUP_RF="rf_guns"
SRC_DIR="/root/custom-pam"   # put your files here
CHECK_TIER_SCRIPT="/usr/local/sbin/check-password-tier.sh"
CHECK_RF_SCRIPT="/usr/local/sbin/check-rf-password.sh"
### =============================== ###

echo "[*] Installing required packages..."
sudo dnf -y install authselect pam libpwquality >/dev/null

echo "[*] Creating groups (idempotent)..."
sudo groupadd -f "${GROUP_APP}"
sudo groupadd -f "${GROUP_RF}"

echo "[*] Selecting baseline auth profile (minimal + faillock)..."
sudo authselect select minimal with-faillock --force

echo "[*] Creating custom authselect profile '${PROFILE}' (if missing)..."
if [ ! -d "/etc/authselect/custom/${PROFILE}" ]; then
  sudo authselect create-profile "${PROFILE}" --base-on minimal
fi

echo "[*] Activating custom profile with faillock..."
sudo authselect select "custom/${PROFILE}" with-faillock --force

echo "[*] Installing password checker scripts..."
sudo install -o root -g root -m 0700 "${SRC_DIR}/check-password-tier.sh" "${CHECK_TIER_SCRIPT}"
sudo install -o root -g root -m 0700 "${SRC_DIR}/check-rf-password.sh" "${CHECK_RF_SCRIPT}"

echo "[*] Copying system-auth and password-auth from ${SRC_DIR}..."
sudo install -o root -g root -m 0644 "${SRC_DIR}/system-auth" "/etc/authselect/custom/${PROFILE}/system-auth"
sudo install -o root -g root -m 0644 "${SRC_DIR}/password-auth" "/etc/authselect/custom/${PROFILE}/password-auth"

echo "[*] Applying authselect changes..."
sudo authselect apply-changes
sudo authselect check || true

echo "[*] Re-applying faillock thresholds (if needed)..."
# If you want different faillock per group, you can patch here.
# For now, we just rely on what’s in your custom system-auth/password-auth.

echo "[*] Done!"
cat <<DONE

Installed profile: custom/${PROFILE}

Scripts:
  - Tier checker: ${CHECK_TIER_SCRIPT}
  - RF-only checker: ${CHECK_RF_SCRIPT}

PAM files:
  - /etc/authselect/custom/${PROFILE}/system-auth
  - /etc/authselect/custom/${PROFILE}/password-auth

To validate:
  sudo passwd alice      # in app_users group
  sudo passwd rf_richard # in rf_guns group
  sudo passwd bob        # in dev_users group
  sudo passwd admin      # in sys_admins group

Check logs:
  journalctl -t password_tier_check

DONE
