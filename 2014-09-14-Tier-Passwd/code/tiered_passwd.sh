#!/usr/bin/env bash
set -euo pipefail

### ======= CONFIGURE HERE ======= ###
PROFILE="two-tier-policy"
GROUP_APP="app_users"
GROUP_RF="rf_guns"
ALLOWED_SPECIALS='._-@'     # <-- allowed special chars for rf_guns (edit to match device limits)
MINLEN_BOTH=12              # both tiers require >= 12
REMEMBER_APP=36
REMEMBER_RF=24
DENY_APP=5; UNLOCK_APP=600  # faillock for app_users
DENY_RF=3;  UNLOCK_RF=900   # tighter for rf_guns
CHECK_SCRIPT="/usr/local/sbin/check-rf-password.sh"
### =============================== ###

need() { command -v "$1" >/dev/null 2>&1; }

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

echo "[*] Installing rf_guns password checker at ${CHECK_SCRIPT} ..."
# This script:
#  - reads candidate password from stdin (pam_exec expose_authtok)
#  - requires at least one char from ALLOWED set
#  - forbids any other special characters
sudo tee "${CHECK_SCRIPT}" >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Read candidate password (from pam_exec with expose_authtok)
# We do not log or echo the password.
IFS= read -r -n 2048 PASSWD || true

# --- BEGIN CONFIG MIRROR (these will be replaced by the caller script) ---
ALLOWED_SPECIALS_PLACEHOLDER
MINLEN_PLACEHOLDER
# --- END CONFIG MIRROR ---

# Escape class for bash regex safely
# (We will build a character class like: [A-Za-z0-9._-@])
escape_regex() {
  local s="$1"
  # escape regex metacharacters inside bracket class context
  printf '%s' "$s" | sed -E 's/([][.^$*+?|(){}\\-])/\\\1/g'
}

ESC_ALLOWED="$(escape_regex "$ALLOWED_SPECIALS")"
# Build a "valid" character class (letters, digits, and only allowed specials)
VALID_CLASS="A-Za-z0-9${ESC_ALLOWED}"

# Checks:
# 1) Minimum length
[[ ${#PASSWD} -ge ${MINLEN} ]] || { echo "Password must be at least ${MINLEN} characters." >&2; exit 1; }

# 2) Required character classes: upper, lower, digit
[[ "$PASSWD" =~ [A-Z] ]] || { echo "Must contain at least one uppercase letter." >&2; exit 1; }
[[ "$PASSWD" =~ [a-z] ]] || { echo "Must contain at least one lowercase letter." >&2; exit 1; }
[[ "$PASSWD" =~ [0-9] ]] || { echo "Must contain at least one digit." >&2; exit 1; }

# 3) Must contain at least one allowed special
[[ "$PASSWD" =~ [${ESC_ALLOWED}] ]] || { echo "Must contain at least one of the allowed special characters: ${ALLOWED_SPECIALS}" >&2; exit 1; }

# 4) Forbid any character outside letters/digits/allowed specials
if [[ "$PASSWD" =~ [^${VALID_CLASS}] ]]; then
  echo "Only these special characters are allowed: ${ALLOWED_SPECIALS}" >&2
  exit 1
fi

exit 0
EOF

# Inject config values into the checker
sudo sed -i \
  -e "s/ALLOWED_SPECIALS_PLACEHOLDER/ALLOWED_SPECIALS='${ALLOWED_SPECIALS//\//\\/}'/" \
  -e "s/MINLEN_PLACEHOLDER/MINLEN=${MINLEN_BOTH}/" \
  "${CHECK_SCRIPT}"

sudo chown root:root "${CHECK_SCRIPT}"
sudo chmod 0700 "${CHECK_SCRIPT}"

echo "[*] Writing system-auth / password-auth with two-tier policy..."
# Common PASSWORD section to embed into both files
read -r -d '' PASSWORD_BLOCK <<PWEOF
########################################
# PASSWORD (password changes)
########################################
# --- rf_guns branch: require upper/lower/digit + >=${MINLEN_BOTH} + allowed specials only ---
password    [success=1 default=ignore] pam_succeed_if.so user notingroup ${GROUP_RF} use_uid
password    requisite   pam_exec.so expose_authtok quiet ${CHECK_SCRIPT}
password    requisite   pam_pwquality.so retry=3 minlen=${MINLEN_BOTH} dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1 \\
                                       difok=3 maxrepeat=2 maxclassrepeat=2 enforce_for_root
password    required    pam_pwhistory.so remember=${REMEMBER_RF} enforce_for_root use_authtok

# --- app_users (and everyone else) branch: full specials allowed ---
password    [success=1 default=ignore] pam_succeed_if.so user ingroup ${GROUP_RF} use_uid
password    requisite   pam_pwquality.so retry=3 minlen=${MINLEN_BOTH} dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1 \\
                                       difok=4 maxrepeat=2 maxclassrepeat=2 enforce_for_root
password    required    pam_pwhistory.so remember=${REMEMBER_APP} enforce_for_root use_authtok

# --- Final apply ---
password    sufficient  pam_unix.so sha512 shadow {if not "without-nullok":nullok} use_authtok
password    required    pam_deny.so
PWEOF

# Helper to render each file in the custom profile
render_file() {
  local target="$1" title="$2"
  sudo tee "$target" >/dev/null <<EOF
#%PAM-1.0
# ${title} (custom: ${PROFILE}, base: minimal + with-faillock)

########################################
# AUTHENTICATION
########################################
auth        required    pam_env.so
auth        required    pam_faildelay.so delay=2000000
auth        required    pam_faillock.so preauth silent     {include if "with-faillock"}
auth        sufficient  pam_unix.so {if not "without-nullok":nullok}
auth        required    pam_faillock.so authfail           {include if "with-faillock"}
auth        required    pam_deny.so

########################################
# ACCOUNT
########################################
account     required    pam_access.so                      {include if "with-pamaccess"}
account     required    pam_faillock.so                    {include if "with-faillock"}
account     required    pam_unix.so

${PASSWORD_BLOCK}

########################################
# SESSION
########################################
session     optional    pam_keyinit.so revoke
session     required    pam_limits.so
session     optional    pam_ecryptfs.so unwrap             {include if "with-ecryptfs"}
-session    optional    pam_systemd.so
session     optional    pam_oddjob_mkhomedir.so            {include if "with-mkhomedir"}
session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session     required    pam_unix.so
EOF
}

render_file "/etc/authselect/custom/${PROFILE}/system-auth"   "system-auth"
render_file "/etc/authselect/custom/${PROFILE}/password-auth" "password-auth"

echo "[*] Applying authselect changes..."
sudo authselect apply-changes
sudo authselect check || true

echo "[*] Tuning faillock thresholds per group (via PAM 'auth' stack)..."
# Patch auth stacks to give rf_guns tighter thresholds
for f in /etc/authselect/custom/${PROFILE}/system-auth /etc/authselect/custom/${PROFILE}/password-auth; do
  # Insert per-group faillock lines after preauth line, and before authfail line
  sudo awk -v grp="${GROUP_RF}" -v deny_rf="${DENY_RF}" -v unlock_rf="${UNLOCK_RF}" \
            -v deny_app="${DENY_APP}" -v unlock_app="${UNLOCK_APP}" '
    BEGIN{pre=0}
    /pam_faillock\.so preauth/ && pre==0 {
      print;
      print "auth        [success=1 default=ignore] pam_succeed_if.so user ingroup " grp " use_uid";
      print "auth        required    pam_faillock.so preauth silent deny=" deny_rf " unlock_time=" unlock_rf " even_deny_root";
      print "auth        [default=1] pam_succeed_if.so user ingroup " grp " use_uid";
      print "auth        required    pam_faillock.so preauth silent deny=" deny_app " unlock_time=" unlock_app;
      pre=1; next
    }
    {print}
  ' "$f" | sudo tee "$f.new" >/dev/null
  sudo mv "$f.new" "$f"

  # Append matching authfail branch right before the authfail line
  sudo awk -v grp="${GROUP_RF}" -v deny_rf="${DENY_RF}" -v unlock_rf="${UNLOCK_RF}" \
            -v deny_app="${DENY_APP}" -v unlock_app="${UNLOCK_APP}" '
    /pam_faillock\.so authfail/ && !done {
      print "auth        [success=1 default=ignore] pam_succeed_if.so user ingroup " grp " use_uid";
      print "auth        required    pam_faillock.so authfail deny=" deny_rf " unlock_time=" unlock_rf " even_deny_root";
      print "auth        [default=1] pam_succeed_if.so user ingroup " grp " use_uid";
      print "auth        required    pam_faillock.so authfail deny=" deny_app " unlock_time=" unlock_app;
      done=1
    }
    {print}
  ' "$f" | sudo tee "$f.new" >/dev/null
  sudo mv "$f.new" "$f"
done

echo "[*] Re-applying authselect after faillock edits..."
sudo authselect apply-changes

cat <<DONE

All set!

- Groups created:
    * ${GROUP_APP}
    * ${GROUP_RF}  (uses allowed specials only: ${ALLOWED_SPECIALS})
- Custom profile: custom/${PROFILE}
- RF checker: ${CHECK_SCRIPT}
- Min length: ${MINLEN_BOTH}
- History: rf_guns=${REMEMBER_RF}, app_users=${REMEMBER_APP}
- Faillock: rf_guns deny=${DENY_RF} unlock=${UNLOCK_RF}; app_users deny=${DENY_APP} unlock=${UNLOCK_APP}

USAGE EXAMPLES:
  sudo useradd -m alice && sudo usermod -aG ${GROUP_APP} alice
  sudo useradd -m bob   && sudo usermod -aG ${GROUP_RF}  bob

  sudo passwd alice   # requires upper/lower/digit/special (any)
  sudo passwd bob     # requires upper/lower/digit + at least one of [${ALLOWED_SPECIALS}], rejects others

Validate:
  faillock --user alice
  faillock --user bob

To change allowed specials, edit ${CHECK_SCRIPT} (ALLOWED_SPECIALS=...) and run:
  sudo authselect apply-changes

DONE
