#!/bin/bash
set -euo pipefail

echo "[+] Starting tiered SSH logging setup..."

# === Group and user definitions ===
declare -a SSH_GROUPS=("rf_guns" "app_users" "app_dev" "sys_admin")
declare -a SSH_USERS=("rf_richard" "app_richard" "dev_richard" "admin_richard")
declare -a USER_GROUP_MAP=(
    "rf_richard:rf_guns"
    "app_richard:app_users"
    "dev_richard:app_dev"
    "admin_richard:sys_admin"
)

# === Group setup ===
echo "[+] Creating groups if they don't exist..."
for group in "${SSH_GROUPS[@]}"; do
    echo "  [>] Checking group: ${group}"
    if ! getent group "$group" > /dev/null; then
        groupadd "$group"
        echo "    [+] Created group: $group"
    else
        echo "    [=] Group $group already exists"
    fi
done

# === User setup ===
echo "[+] Creating users and assigning them to groups..."
for pair in "${USER_GROUP_MAP[@]}"; do
    IFS=':' read -r user group <<< "$pair"
    if ! id "$user" &>/dev/null; then
        useradd -m -G "$group" "$user"
        echo "    [+] Created user: $user in group $group"
    else
        usermod -aG "$group" "$user"
        echo "    [=] User $user already exists, ensured in group $group"
    fi
done

# === Install auditd and rsyslog ===
echo "[+] Installing auditd and rsyslog..."
dnf install -y audit rsyslog

echo "[+] Enabling rsyslog (auditd is socket-activated)..."
systemctl enable --now rsyslog

# === Create audit rules file ===
AUDIT_RULE_FILE="/etc/audit/rules.d/99-ssh-users.rules"
echo "[+] Creating audit rules in: $AUDIT_RULE_FILE"

cat > "$AUDIT_RULE_FILE" <<EOF
# Track executed commands for all non-system users
-a always,exit -F arch=b64 -F auid>=1000 -F auid!=4294967295 -S execve -k ssh_user_exec
-a always,exit -F arch=b32 -F auid>=1000 -F auid!=4294967295 -S execve -k ssh_user_exec

# Watch all home directories for .bashrc modifications
-w /home/ -p wa -k bashrc_watch
EOF

# === PAM TTY auditing for sys_admin group ===
PAM_FILE="/etc/pam.d/sshd"
TTY_LINE="session required pam_tty_audit.so enable=group open_only group=sys_admin"
if ! grep -Fxq "$TTY_LINE" "$PAM_FILE"; then
    echo "$TTY_LINE" >> "$PAM_FILE"
    echo "    [+] PAM TTY auditing added for sys_admin"
else
    echo "    [=] PAM TTY auditing already present"
fi

# === Rsyslog config to split SSH logs by group ===
echo "[+] Setting up rsyslog log splitting for group logins..."
mkdir -p /var/log/ssh
chmod 750 /var/log/ssh
chown root:root /var/log/ssh

RSYSLOG_CONF="/etc/rsyslog.d/30-ssh-group-logs.conf"
cat > "$RSYSLOG_CONF" <<'EOF'
$template GroupLogFormat,"[%timestamp%] %hostname% %programname%: %msg%\n"

if $programname == 'sshd' and $msg contains 'Accepted' then {
    if $msg contains 'rf_guns' then -/var/log/ssh/rf_guns.log;GroupLogFormat
    else if $msg contains 'app_users' then -/var/log/ssh/app_users.log;GroupLogFormat
    else if $msg contains 'app_dev' then -/var/log/ssh/app_dev.log;GroupLogFormat
    else if $msg contains 'sys_admin' then -/var/log/ssh/sys_admin.log;GroupLogFormat
}
& stop
EOF

# === Bashrc monitoring ===
echo "[+] Ensuring .bashrc audit watches are set..."
for user in "${SSH_USERS[@]}"; do
    bashrc="/home/$user/.bashrc"
    if [ ! -f "$bashrc" ]; then
        echo "    [!] $bashrc not found, creating..."
        sudo -u "$user" touch "$bashrc"
    fi
    auditctl -w "$bashrc" -p wa -k bashrc_edit || true
    echo "    [*] Watching: $bashrc"
done

# === Reload audit rules ===
echo "[+] Flushing current audit rules to prevent duplication..."
auditctl -D

echo "[+] Loading new audit rules using augenrules..."
augenrules --load
# DO NOT re-run auditctl -R after augenrules — it causes duplication

echo "[+] Restarting rsyslog..."
systemctl restart rsyslog

echo "[✔] SSH tiered logging setup complete."

echo
echo "==[ NEXT STEPS ]=="
echo "- Exec command logs:       ausearch -k ssh_user_exec"
echo "- .bashrc modifications:   ausearch -k bashrc_edit"
echo "- Home .bashrc watches:    ausearch -k bashrc_watch"
echo "- SSH log files:           /var/log/ssh/{rf_guns,app_users,app_dev,sys_admin}.log"
