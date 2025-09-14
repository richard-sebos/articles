#!/usr/bin/env bash
set -euo pipefail

### ======= CONFIGURE HERE ======= ###
PROFILE="two-tier-policy"
GROUP_APP="app_users"
GROUP_RF="rf_guns"
GROUP_DEV="app_devs"
GROUP_SYS="sys_admins"
SRC_DIR="/root/tier/custom-pam"   # directory containing your PAM files & check-password-tier.sh
CHECK_SCRIPT="/usr/local/sbin/check-password-tier.sh"
### =============================== ###

echo "[*] Installing required packages..."
# authselect: manage PAM profiles cleanly
# libpwquality: password complexity enforcement
# pam: base PAM libs (already installed on most systems)
sudo dnf -y install authselect pam libpwquality >/dev/null

echo "[*] Creating groups (idempotent)..."
# These groups determine which password policy applies
sudo groupadd -f "${GROUP_APP}"
sudo groupadd -f "${GROUP_RF}"
sudo groupadd -f "${GROUP_DEV}"
sudo groupadd -f "${GROUP_SYS}"

echo "[*] Selecting baseline auth profile (minimal + faillock)..."
# Start from a minimal baseline profile and include account lockout support
sudo authselect select minimal with-faillock --force

echo "[*] Creating custom authselect profile '${PROFILE}' (if missing)..."
# Create your custom profile only once
if [ ! -d "/etc/authselect/custom/${PROFILE}" ]; then
  sudo authselect create-profile "${PROFILE}" --base-on minimal
fi

echo "[*] Activating custom profile with faillock..."
sudo authselect select "custom/${PROFILE}" with-faillock --force

echo "[*] Installing password tier validation script..."
# This script performs per-group password validation and logs failures to journalctl
sudo install -o root -g root -m 0700 "${SRC_DIR}/check-password-tier.sh" "${CHECK_SCRIPT}"

echo "[*] Copying system-auth and password-auth from ${SRC_DIR}..."
# These files must already contain the minimal password section that calls check-password-tier.sh
sudo install -o root -g root -m 0644 "${SRC_DIR}/system-auth"   "/etc/authselect/custom/${PROFILE}/system-auth"
sudo install -o root -g root -m 0644 "${SRC_DIR}/password-auth" "/etc/authselect/custom/${PROFILE}/password-auth"

echo "[*] Applying authselect changes..."
sudo authselect apply-changes
sudo authselect check || true

echo "[*] Done!"
cat <<DONE

Installed profile: custom/${PROFILE}

Groups created:
  - ${GROUP_RF}   → rf_guns (12 chars, moderate complexity, shorter history)
  - ${GROUP_APP}  → app_users (14 chars, balanced policy)
  - ${GROUP_DEV}  → app_devs (16 chars, stricter rules)
  - ${GROUP_SYS}  → sys_admins (default, 20 chars, strongest policy)

Scripts:
  - ${CHECK_SCRIPT} (validates password per group, logs rejections)

PAM files in use:
  - /etc/authselect/custom/${PROFILE}/system-auth
  - /etc/authselect/custom/${PROFILE}/password-auth

To test:
  sudo useradd -m -G ${GROUP_RF} rf_test
  sudo passwd rf_test      # enforces rf_guns rules

  sudo useradd -m -G ${GROUP_APP} app_test
  sudo passwd app_test     # enforces app_users rules

  sudo useradd -m -G ${GROUP_DEV} dev_test
  sudo passwd dev_test     # enforces app_devs rules

  sudo useradd -m -G ${GROUP_SYS} admin_test
  sudo passwd admin_test   # enforces sys_admins rules (default branch)

Helpdesk/admin tip:
  If a user reports "BAD PASSWORD" errors, check the rejection reason with:
    journalctl -t password_tier_check

Validate:
  sudo authselect check
  faillock --user <username>

DONE
