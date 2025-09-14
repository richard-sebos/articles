#!/usr/bin/env bash
set -euo pipefail

USER="$PAM_USER"

# Read candidate password (provided by pam_exec expose_authtok)
IFS= read -r -n 2048 PASSWD || true

# Logger function
logfail() {
  local group="$1" msg="$2"
  # Print to stderr (so passwd shows user why it failed)
  echo "[$group] $msg" >&2
  # Also log to syslog/journal with a custom tag
  logger -t password_tier_check "user=$USER group=$group reason=\"$msg\""
  exit 1
}

# Select tier by group
if id -nG "$USER" | grep -qw rf_guns; then
    GROUP="rf_guns"; MINLEN=12
    [[ ${#PASSWD} -ge $MINLEN ]] || logfail "$GROUP" "Too short (min $MINLEN)"
    [[ "$PASSWD" =~ [A-Z] ]] || logfail "$GROUP" "Missing uppercase"
    [[ "$PASSWD" =~ [a-z] ]] || logfail "$GROUP" "Missing lowercase"
    [[ "$PASSWD" =~ [0-9] ]] || logfail "$GROUP" "Missing digit"

elif id -nG "$USER" | grep -qw app_users; then
    GROUP="app_users"; MINLEN=14
    [[ ${#PASSWD} -ge $MINLEN ]] || logfail "$GROUP" "Too short (min $MINLEN)"
    [[ "$PASSWD" =~ [A-Z] ]] || logfail "$GROUP" "Missing uppercase"
    [[ "$PASSWD" =~ [a-z] ]] || logfail "$GROUP" "Missing lowercase"
    [[ "$PASSWD" =~ [0-9] ]] || logfail "$GROUP" "Missing digit"
    [[ "$PASSWD" =~ [^A-Za-z0-9] ]] || logfail "$GROUP" "Missing special"

elif id -nG "$USER" | grep -qw app_devs; then
    GROUP="app_devs"; MINLEN=16
    [[ ${#PASSWD} -ge $MINLEN ]] || logfail "$GROUP" "Too short (min $MINLEN)"
    [[ "$PASSWD" =~ [A-Z] ]] || logfail "$GROUP" "Missing uppercase"
    [[ "$PASSWD" =~ [a-z] ]] || logfail "$GROUP" "Missing lowercase"
    [[ "$PASSWD" =~ [0-9] ]] || logfail "$GROUP" "Missing digit"
    [[ "$PASSWD" =~ [^A-Za-z0-9] ]] || logfail "$GROUP" "Missing special"

else
    # Default = sys_admins and others
    GROUP="sys_admins"; MINLEN=20
    [[ ${#PASSWD} -ge $MINLEN ]] || logfail "$GROUP" "Too short (min $MINLEN)"
    [[ "$PASSWD" =~ [A-Z] ]] || logfail "$GROUP" "Missing uppercase"
    [[ "$PASSWD" =~ [a-z] ]] || logfail "$GROUP" "Missing lowercase"
    [[ "$PASSWD" =~ [0-9] ]] || logfail "$GROUP" "Missing digit"
    [[ "$PASSWD" =~ [^A-Za-z0-9] ]] || logfail "$GROUP" "Missing special"
fi

# If we get here, password is valid
exit 0

