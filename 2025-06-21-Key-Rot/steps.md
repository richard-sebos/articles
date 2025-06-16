Absolutely! Here's a **ready-to-use script** that enforces **SSH key expiration and rotation policies** using a JSON file as the key store. It’s meant to be used with `AuthorizedKeysCommand`.

---

## ✅ Summary

* 📁 Stores SSH keys with expiration dates in `/etc/ssh/user_keys.json`
* 🛠 Filters out expired keys
* 🔐 Works with OpenSSH's `AuthorizedKeysCommand`

---

## 📄 Step 1: Create the JSON Key Store

**File**: `/etc/ssh/user_keys.json`

```json
{
  "rchamberlain": [
    {
      "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEXAMPLE1 user1@example.com",
      "expires": "2025-08-01"
    },
    {
      "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEXPIRED1 user1@example.com",
      "expires": "2024-01-01"
    }
  ],
  "devuser": [
    {
      "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCEXAMPLE2 dev@example.com",
      "expires": "2025-09-15"
    }
  ]
}
```

---

## 🔧 Step 2: Create the AuthorizedKeysCommand Script

**File**: `/usr/local/bin/ssh-key-expiry-check`

```bash
#!/bin/bash

# Usage: sshd calls this script with the username as the only argument
USER="$1"
KEYS_FILE="/etc/ssh/user_keys.json"

# Check that jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found" >&2
    exit 1
fi

# Validate file exists
if [ ! -f "$KEYS_FILE" ]; then
    echo "Key store not found" >&2
    exit 1
fi

# Get current time in seconds
NOW=$(date +%s)

# Output valid (unexpired) keys
jq -r --arg user "$USER" --argjson now "$NOW" '
  .[$user][]? | select((.expires | fromdateiso8601) >= $now) | .key
' "$KEYS_FILE"
```

**Make it executable:**

```bash
chmod +x /usr/local/bin/ssh-key-expiry-check
```

---

## ⚙️ Step 3: Update `sshd_config`

Edit `/etc/ssh/sshd_config` and add:

```conf
AuthorizedKeysCommand /usr/local/bin/ssh-key-expiry-check
AuthorizedKeysCommandUser nobody
```

---

## 🔁 Step 4: Restart SSH

```bash
sudo systemctl restart sshd
```

---

## ✅ Test

Try logging in with:

* A valid key → ✅ Allowed
* An expired key → ❌ Denied (key not found)

---

Would you like an Ansible playbook to manage this, or a version that reads from an SQLite or LDAP source instead of JSON?
