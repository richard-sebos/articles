#!/usr/bin/env bash
set -euo pipefail

# User and group context
USER="${PAM_USER:-}"
PASSWD=""
IFS= read -r -n 2048 PASSWD || true

# Default values
MINLEN=12
ALLOWED_SPECIALS='!@#$%^&*()_+=-[]{}:;.,?'
MAXAGE=180
REMEMBER=24
ROLE="default"

# Role detection (group-based)
if id -nG "$USER" 2>/dev/null | grep -qw rf_guns; then
  ROLE="rf_guns"
  MINLEN=12
  ALLOWED_SPECIALS='._-@'
  REMEMBER=24
elif id -nG "$USER" 2>/dev/null | grep -qw office_users; then
  ROLE="office_users"
  MINLEN=14
  ALLOWED_SPECIALS='!@#$%^&*()_+=-[]{}:;.,?'
  REMEMBER=36
elif id -nG "$USER" 2>/dev/null | grep -qw dev_users; then
  ROLE="dev_users"
  MINLEN=16
  ALLOWED_SPECIALS='!@#$%^&*()_+=-[]{}:;.,?'
  REMEMBER=48
elif id -nG "$USER" 2>/dev/null | grep -qw sys_admins; then
  ROLE="sys_admins"
  MINLEN=20
  ALLOWED_SPECIALS='!@#$%^&*()_+=-[]{}:;.,?'
  REMEMBER=64
fi

# Regex
VALID_REGEX="^[A-Za-z0-9$(printf %s "$ALLOWED_SPECIALS" | sed 's/[]\/$*.^|[]/\\&/g')]+$"
SPECIAL_REGEX="[$ALLOWED_SPECIALS]"

# Track errors
errors=()

# Checks
if [[ ${#PASSWD} -lt ${MINLEN} ]]; then
  errors+=("[$ROLE] Password must be at least ${MINLEN} characters.")
fi
if [[ ! "$PASSWD" =~ [A-Z] ]]; then
  errors+=("[$ROLE] Must contain at least one uppercase letter.")
fi
if [[ ! "$PASSWD" =~ [a-z] ]]; then
  errors+=("[$ROLE] Must contain at least one lowercase letter.")
fi
if [[ ! "$PASSWD" =~ [0-9] ]]; then
  errors+=("[$ROLE] Must contain at least one digit.")
fi
if [[ ! "$PASSWD" =~ ${SPECIAL_REGEX} ]]; then
  errors+=("[$ROLE] Must contain at least one special character from: ${ALLOWED_SPECIALS}")
fi
if [[ ! "$PASSWD" =~ ${VALID_REGEX} ]]; then
  errors+=("[$ROLE] Only these special characters are allowed: ${ALLOWED_SPECIALS}")
fi

# Output results
if (( ${#errors[@]} > 0 )); then
  for err in "${errors[@]}"; do
    echo "$err" >&2
    logger -t password_tier_check "$err"
  done
  exit 1
fi

exit 0
