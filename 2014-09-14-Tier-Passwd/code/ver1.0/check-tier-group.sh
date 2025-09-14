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
