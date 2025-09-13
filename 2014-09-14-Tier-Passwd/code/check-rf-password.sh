#!/usr/bin/env bash
set -euo pipefail

# Config
ALLOWED_SPECIALS='._-@'
MINLEN=12

# Read candidate password from stdin (provided by pam_exec with expose_authtok)
IFS= read -r -n 2048 PASSWD || true

# Regex
VALID_REGEX='^[A-Za-z0-9._\-@]+$'
SPECIAL_REGEX='[._\-@]'

# Logging function
log_error() {
  local msg="$1"
  echo "$msg" >&2                          # show to user
  logger -t rf_password_check "$msg"       # log to journald
}

# Track errors
errors=()

# Checks
if [[ ${#PASSWD} -lt ${MINLEN} ]]; then
  errors+=("Password must be at least ${MINLEN} characters.")
fi
if [[ ! "$PASSWD" =~ [A-Z] ]]; then
  errors+=("Must contain at least one uppercase letter.")
fi
if [[ ! "$PASSWD" =~ [a-z] ]]; then
  errors+=("Must contain at least one lowercase letter.")
fi
if [[ ! "$PASSWD" =~ [0-9] ]]; then
  errors+=("Must contain at least one digit.")
fi
if [[ ! "$PASSWD" =~ ${SPECIAL_REGEX} ]]; then
  errors+=("Must contain at least one of the allowed special characters: ${ALLOWED_SPECIALS}")
fi
if [[ ! "$PASSWD" =~ ${VALID_REGEX} ]]; then
  errors+=("Only these special characters are allowed: ${ALLOWED_SPECIALS}")
fi

# Output results
if (( ${#errors[@]} > 0 )); then
  for err in "${errors[@]}"; do
    log_error "$err"
  done
  exit 1
fi

exit 0
