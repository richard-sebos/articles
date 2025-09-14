#!/usr/bin/env bash
set -euo pipefail

### ======= CONFIGURE HERE ======= ###
PROFILE="two-tier-policy"
GROUP_APP="app_users"
GROUP_RF="rf_guns"
GROUP_DEV="app_devs"
GROUP_SYS="sys_admins"
SRC_DIR="/root/tier/custom-pam"   # directory containing your PAM files
CHECK_TIER_SCRIPT="/usr/local/sbin/check-password-tier.sh"
### =============================== ###

echo "[*] Installing required packages..."
sudo dnf -y install authselect pam libpwquality >/dev/null

echo "[*] Creating groups (idempotent)..."
sudo groupadd -f "${GROUP_APP}"
sudo groupadd -f "${GROUP_RF}"
sudo groupadd -f "${GROUP_DEV}"
sudo groupadd -f "${GROUP_SYS}"

echo "[*] Selecting baseline auth profile (minimal + faillock)..."
sudo authselect select minimal with-faillock --force

echo "[*] Creating custom authselect profile '${PROFILE}' (if missing)..."
if [ ! -d "/etc/authselect/custom/${PROFILE}" ]; then
  sudo authselect create-profile "${PROFILE}" --base-on minimal
fi

echo "[*] Activating custom profile with faillock..."
sudo authselect select "custom/${PROFILE}" with-faillock --force

echo "[*] Installing tiered password checker..."
sudo tee "${CHECK_TIER_SCRIPT}" >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

USER="${PAM_USER:-$(id -un)}"
LOGTAG="password_tier_check"

# Read candidate password (from PAM expose_authtok)
IFS= read -r -n 2048 PASSWD || true

logfail() {
    local group="$1" msg="$2"
    echo "[$group] $msg" >&2
    logger -t "$LOGTAG" "user=$USER group=$group reason=\"$msg\" length=${#PASSWD}"
    exit 1
}

# Default = sys_admins (strongest)
GROUP="sys_admins"; MINLEN=20; NEED_SPECIAL=1; NEED_UPPER=1; NEED_LOWER=1; NEED_DIGIT=1

# Group-specific overrides
if id -nG "$USER" | grep -qw rf_guns; then
    GROUP="rf_guns"; MINLEN=12; NEED_SPECIAL=0
elif id -nG "$USER" | grep -qw app_users; then
    GROUP="app_users"; MINLEN=14
elif id -nG "$USER" | grep -qw app_devs; then
    GROUP="app_devs"; MINLEN=16
fi

# --- Checks ---
[[ ${#PASSWD} -ge $MINLEN ]] || logfail "$GROUP" "Too short (min $MINLEN)"
[[ $NEED_UPPER -eq 0 || "$PASSWD" =~ [A-Z] ]] || logfail "$GROUP" "Missing uppercase"
[[ $NEED_LOWER -eq 0 || "$PASSWD" =~ [a-z] ]] || logfail "$GROUP" "Missing lowercase"
[[ $NEED_DIGIT -eq 0 || "$PASSWD" =~ [0-9] ]] || logfail "$GROUP" "Missing digit"
[[ $NEED_SPECIAL -eq 0 || "$PASSWD" =~ [^A-Za-z0-9] ]] || logfail "$GROUP" "Missing special"

logger -t "$LOGTAG" "user=$USER group=$GROUP password accepted length=${#PASSWD}"
exit 0
EOF
sudo chown root:root "${CHECK_TIER_SCRIPT}"
sudo chmod 0700 "${CHECK_TIER_SCRIPT}"

echo "[*] Copying system-auth and password-auth from ${SRC_DIR}..."
# These should already contain only a pam_exec reference to ${CHECK_TIER_SCRIPT}
sudo install -o root -g root -m 0644 "${SRC_DIR}/system-auth"   "/etc/authselect/custom/${PROFILE}/system-auth"
sudo install -o root -g root -m 0644 "${SRC_DIR}/password-auth" "/etc/authselect/custom/${PROFILE}/password-auth"

echo "[*] Replacing /etc/pam.d/passwd with safe template..."
sudo tee /etc/pam.d/passwd >/dev/null <<'EOF'
#%PAM-1.0
auth       sufficient   pam_rootok.so
auth       include      system-auth
account    include      system-auth
password   substack     system-auth
-password  optional     pam_gnome_keyring.so use_authtok
password   substack     postlogin
session    include      system-auth
session    include      postlogin
EOF

echo "[*] Applying authselect changes..."
sudo authselect apply-changes
sudo authselect check || true

echo "[*] Done!"
cat <<DONE

Installed profile: custom/${PROFILE}

Groups created:
  - ${GROUP_RF}   → rf_guns (12-char min, no special required)
  - ${GROUP_APP}  → app_users (14-char min, must include special)
  - ${GROUP_DEV}  → app_devs (16-char min, stricter rules)
  - ${GROUP_SYS}  → sys_admins (default, 20-char min, strongest)

Helper script:
  - ${CHECK_TIER_SCRIPT}

Logs:
  journalctl -t password_tier_check

PAM files in use:
  - /etc/authselect/custom/${PROFILE}/system-auth
  - /etc/authselect/custom/${PROFILE}/password-auth
  - /etc/pam.d/passwd

Test:
  sudo useradd -m -G ${GROUP_RF} rf_test
  sudo passwd rf_test      # enforces rf_guns rules

  sudo useradd -m -G ${GROUP_APP} app_test
  sudo passwd app_test     # enforces app_users rules

  sudo useradd -m -G ${GROUP_DEV} dev_test
  sudo passwd dev_test     # enforces app_devs rules

  sudo useradd -m -G ${GROUP_SYS} admin_test
  sudo passwd admin_test   # enforces sys_admins rules

DONE
