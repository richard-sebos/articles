#!/bin/bash

# SSH Secure Session Test Script
# Purpose: Verify restricted session environment for hardened SSH access

LOG_TAG="secure_ssh_test"
FAILED=0

log() {
    logger -t "$LOG_TAG" "$1"
    echo "[LOG] $1"
}

fail() {
    log "❌ FAIL: $1"
    FAILED=1
}

pass() {
    log "✅ PASS: $1"
}

# --------------------------------------
# Session Info
# --------------------------------------
log "Session started by user $USER"
log "SSH_CLIENT: $SSH_CLIENT"
log "SSH_CONNECTION: $SSH_CONNECTION"
log "TERM: $TERM"
log "HOME: $HOME"

# --------------------------------------
# Check SSH-only Session
# --------------------------------------
if [[ -z "$SSH_CONNECTION" ]]; then
    fail "Not an SSH session!"
else
    pass "SSH connection detected"
fi

# --------------------------------------
# Check TTY is disabled (if configured that way)
if [[ "$TERM" == "dumb" ]] || [[ -z "$TERM" ]]; then
    pass "TTY disabled or non-interactive"
else
    log "TTY is present: $TERM"
fi

# --------------------------------------
# Check shell access attempt
if env | grep -qi 'bash\|zsh\|sh'; then
    fail "User appears to have access to a shell environment!"
else
    pass "No visible shell access in env"
fi

# --------------------------------------
# Test write permissions (HOME, /tmp)
TMPTEST="$HOME/.write_test"
touch "$TMPTEST" &>/dev/null && {
    rm -f "$TMPTEST"
    fail "User can write to home directory"
} || pass "No write access to home directory"

touch /tmp/test_ssh_write &>/dev/null && {
    rm -f /tmp/test_ssh_write
    fail "User can write to /tmp"
} || pass "No write access to /tmp"

# --------------------------------------
# Test escape to shell (via subshell)
if bash -c 'echo "Shell escape test"' 2>/dev/null; then
    fail "Shell escape via bash possible"
else
    pass "No shell escape via bash"
fi

# --------------------------------------
# Test sudo access
if sudo -l &>/dev/null; then
    fail "User has sudo access!"
else
    pass "No sudo access"
fi

# --------------------------------------
# Test auditd logging
AUDIT_FILE="/var/log/audit/audit.log"
if grep "$LOG_TAG" "$AUDIT_FILE" &>/dev/null; then
    pass "Auditd is logging events"
else
    fail "Auditd does not appear to be logging this session"
fi

# --------------------------------------
# Summary
echo
if [[ $FAILED -eq 0 ]]; then
    echo "✅ All secure SSH session checks passed."
    log "Session check completed successfully"
else
    echo "❌ One or more security checks failed. Review logs."
    log "Session check failed"
fi

# Exit to terminate session
exit 0
