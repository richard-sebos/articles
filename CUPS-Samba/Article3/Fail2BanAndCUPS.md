Certainly — here’s the full **outline and command reference** for your article:

---

## 🔒 **Fail2Ban and CUPS (with PAM)**

### *Protecting the CUPS Web Interface from Brute-Force Attacks*

---

### ✅ **Article Goal**

Demonstrate how to defend the CUPS admin web interface from unauthorized access attempts using **Fail2Ban**, with a focus on PAM integration for granular login tracking.

---

### 🧱 **Outline**

---

### 1. **Introduction**

* CUPS offers a convenient web interface, but it’s a potential target if exposed.
* Brute-force attempts on `/admin` could compromise print control or execute commands if not protected.
* Using **PAM** and **Fail2Ban**, we can create a defensive layer around authentication failures.

---

### 2. **Prerequisites**

* CUPS is installed and accessible via `https://localhost:631`
* Admin access is configured using PAM (see Article 2)
* Fail2Ban is installed

#### ➤ Install Fail2Ban:

```bash
sudo apt install fail2ban  # Debian/Ubuntu
# or
sudo dnf install fail2ban  # RHEL/Rocky/Fedora
```

---

### 3. **Understanding CUPS Authentication with PAM**

* CUPS uses PAM stack: `/etc/pam.d/cups`
* Auth failures are logged in:

  * `/var/log/auth.log` (Debian)
  * `/var/log/secure` (RHEL-based)
  * Or systemd: `journalctl -u cups`

---

### 4. **Create a Custom Fail2Ban Filter for CUPS**

#### ➤ Create filter file:

```bash
sudo nano /etc/fail2ban/filter.d/cups-auth.conf
```

#### ➤ Example filter (Debian-based):

```ini
[Definition]
failregex = .*cupsd.*pam_unix\(cups:auth\): authentication failure;.*rhost=<HOST>
ignoreregex =
```

* Adjust `failregex` if you use a different PAM module (e.g., `pam_faillock` or `pam_google_authenticator`)

---

### 5. **Configure Fail2Ban Jail for CUPS**

#### ➤ Add to jail local config:

```bash
sudo nano /etc/fail2ban/jail.local
```

#### ➤ Example CUPS jail:

```ini
[cups-auth]
enabled = true
port = 631
filter = cups-auth
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h
findtime = 10m
```

* For RHEL-based systems, change `logpath` to `/var/log/secure`

---

### 6. **Test the Setup**

#### ➤ Restart Fail2Ban:

```bash
sudo systemctl restart fail2ban
```

#### ➤ Check status:

```bash
sudo fail2ban-client status cups-auth
```

#### ➤ Trigger a ban:

* Attempt incorrect logins via the CUPS web UI ([https://localhost:631/admin](https://localhost:631/admin))
* Check:

```bash
sudo fail2ban-client status
sudo iptables -L -n
```

---

### 7. **Optional: Log Auth Events with PAM Exec**

* Use `pam_exec.so` to log or alert on login failures

#### ➤ Example in `/etc/pam.d/cups`:

```pam
auth [default=ignore success=1] pam_exec.so /usr/local/bin/cups_auth_alert.sh
```

#### ➤ Example script:

```bash
#!/bin/bash
logger -p auth.notice "CUPS login attempt by $PAM_USER from $PAM_RHOST"
```

Make sure it's executable:

```bash
sudo chmod +x /usr/local/bin/cups_auth_alert.sh
```

---

### 8. **Conclusion**

* With Fail2Ban and PAM integration, you’ve added a powerful layer of brute-force protection to your CUPS server.
* Effective for home labs, small business setups, and even exposed CUPS interfaces behind a firewall.
* In upcoming articles, we’ll log access attempts centrally and explore alerting via email or webhooks.

---

Would you like this outline in Markdown format for publishing?
