#!/usr/bin/env bash
set -euo pipefail

USER="${PAM_USER:-$(id -un)}"
LOGTAG="pam_group_check"

# Group to check is passed as first argument
TARGET_GROUP="$1"

if id -nG "$USER" 2>/dev/null | grep -qw "$TARGET_GROUP"; then
    logger -t "$LOGTAG" "user=$USER is in $TARGET_GROUP"
    exit 0
else
    logger -t "$LOGTAG" "user=$USER not in $TARGET_GROUP"
    exit 1
fi

[root@build2 custom-pam]# cat check-password-tier.sh
#!/usr/bin/env bash
set -euo pipefail

USER="${PAM_USER:-$(id -un)}"
LOGTAG="password_tier_check"

# Read candidate password from stdin (via pam_exec expose_authtok)
IFS= read -r -n 2048 PASSWD || true

logfail() {
    local group="$1" msg="$2"
    echo "[$group] $msg" >&2
    logger -t "$LOGTAG" "user=$USER group=$group reason=\"$msg\" length=${#PASSWD}"
    exit 1
}

# Default policy variables
GROUP="sys_admins"; MINLEN=20; NEED_SPECIAL=1; NEED_UPPER=1; NEED_LOWER=1; NEED_DIGIT=1; HISTORY=64

# Group-specific overrides
if id -nG "$USER" | grep -qw rf_guns; then
    GROUP="rf_guns"; MINLEN=12; HISTORY=24; NEED_SPECIAL=0
elif id -nG "$USER" | grep -qw app_users; then
    GROUP="app_users"; MINLEN=14; HISTORY=36
elif id -nG "$USER" | grep -qw app_devs; then
    GROUP="app_devs"; MINLEN=16; HISTORY=48
fi

# --- Checks ---
[[ ${#PASSWD} -ge $MINLEN ]] || logfail "$GROUP" "Too short (min $MINLEN)"
[[ $NEED_UPPER -eq 0 || "$PASSWD" =~ [A-Z] ]] || logfail "$GROUP" "Missing uppercase"
[[ $NEED_LOWER -eq 0 || "$PASSWD" =~ [a-z] ]] || logfail "$GROUP" "Missing lowercase"
[[ $NEED_DIGIT -eq 0 || "$PASSWD" =~ [0-9] ]] || logfail "$GROUP" "Missing digit"
[[ $NEED_SPECIAL -eq 0 || "$PASSWD" =~ [^A-Za-z0-9] ]] || logfail "$GROUP" "Missing special"

# Log success
logger -t "$LOGTAG" "user=$USER group=$GROUP password accepted length=${#PASSWD}"

exit 0
