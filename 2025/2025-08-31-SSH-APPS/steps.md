Absolutely — that’s a smart and hands-on way to validate your **SSH-restricted session setup** in your homelab. Below is a **hardened, auditable shell script** designed to be used as the user’s `ForceCommand` or default shell.

This script **verifies the environment**, **logs critical session info**, performs **security checks**, and **exits** cleanly. It's ideal for testing setups where a user is only supposed to run one app or task during an SSH session.

---

## ✅ **Purpose of the Script:**

* Log and verify the SSH environment
* Confirm restricted access (TTY, file access, shell escape detection)
* Test `auditd`, logging, file permissions, and shell lockdown
* Print result (PASS/FAIL)
* Exit cleanly without leaving a shell

---

## 🔐 **Step-by-Step Security Test Script**

Save this as:
`/usr/local/bin/ssh_secure_test.sh`
Make it **executable and owned by root**:

```bash
chmod 755 /usr/local/bin/ssh_secure_test.sh
chown root:root /usr/local/bin/ssh_secure_test.sh
```

### 📜 `ssh_secure_test.sh`

```bash
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
```

---

## 🔧 **How to Use This for a Test User**

1. **Create a test user (optional):**

```bash
sudo useradd -m -s /bin/bash sshapptest
sudo passwd sshapptest
```

2. **Restrict their session with `ForceCommand`:**

Add to the bottom of `/etc/ssh/sshd_config`:

```ssh
Match User sshapptest
    ForceCommand /usr/local/bin/ssh_secure_test.sh
    AllowTcpForwarding no
    PermitTTY no
    X11Forwarding no
```

3. **Restart SSHD:**

```bash
sudo systemctl restart sshd
```

4. **SSH into the server as the restricted user:**

```bash
ssh sshapptest@your.server.ip
```

5. **Review logs:**

```bash
sudo grep secure_ssh_test /var/log/messages
sudo ausearch -k secure_ssh_test
```

---

## 📊 Optional Enhancements

| Feature                    | How                                                     |
| -------------------------- | ------------------------------------------------------- |
| **Email alert on failure** | Add `mail` or `sendmail` hook to alert on failure       |
| **Syslog forwarding**      | Ensure rsyslog sends events to a centralized log server |
| **Ansible role**           | Let me know if you want to automate this setup          |
| **Colorized output**       | Add ANSI color codes for visual clarity                 |
| **JSON log mode**          | Easy integration with ELK/Splunk/SIEM                   |

---

Would you like a version of this test wrapped into an **Ansible playbook** that deploys the user, script, SSH config, and reboots `sshd`?
