Absolutely — here’s a detailed **outline and command reference** for your article:

---

## 🔐 **Securing CUPS (with PAM)**

### ✅ **Article Goal**

Guide users through securing a CUPS print server by enabling HTTPS, restricting access to administration functions, leveraging PAM for user/group-based control, applying firewall rules, and hardening print filters.

---

### 🧱 **Outline**

---

### 1. **Introduction**

* CUPS is powerful but often misconfigured in home labs and SMBs.
* Why securing a print server matters (network exposure, lateral movement, data exfiltration).
* Quick recap: CUPS listens on port **631**, uses IPP, and supports multiple protocols.

---

### 2. **Restricting Access to the CUPS Web Interface**

#### ➤ Configuration: `/etc/cups/cupsd.conf`

* Limit access to localhost or admin subnet only:

```apache
<Location />
  Order allow,deny
  Allow localhost
  # Allow a specific subnet if needed
  Allow from 192.168.1.0/24
</Location>

<Location /admin>
  Order allow,deny
  Allow localhost
  Allow from 192.168.1.0/24
  AuthType Default
  Require user @system
</Location>
```

* Restart CUPS to apply:

```bash
sudo systemctl restart cups
```

---

### 3. **Enable SSL for Web Interface**

#### ➤ Generate self-signed cert:

```bash
sudo mkdir /etc/cups/ssl
openssl req -x509 -newkey rsa:2048 -keyout /etc/cups/ssl/cups.key \
-out /etc/cups/ssl/cups.crt -days 365 -nodes
```

#### ➤ Edit `cupsd.conf`:

```apache
DefaultEncryption Required
ServerCertificate /etc/cups/ssl/cups.crt
ServerKey /etc/cups/ssl/cups.key
```

* Then restart:

```bash
sudo systemctl restart cups
```

* Web interface now available at: `https://localhost:631`

---

### 4. **Controlling Access via PAM**

* CUPS uses **PAM** stack at `/etc/pam.d/cups`

#### ➤ Example: restrict admin access by group using `pam_succeed_if`:

```pam
auth required pam_env.so
auth required pam_unix.so
auth [success=1 default=ignore] pam_succeed_if.so user ingroup print_admins
auth requisite pam_deny.so
auth required pam_permit.so
```

* Create `print_admins` group and add users:

```bash
sudo groupadd print_admins
sudo usermod -aG print_admins alice
```

---

### 5. **Firewall Best Practices**

* Limit access to port **631/tcp** to trusted clients or management subnet

#### ➤ UFW Example:

```bash
sudo ufw allow from 192.168.1.0/24 to any port 631 proto tcp
```

#### ➤ Firewalld Example:

```bash
sudo firewall-cmd --add-rich-rule='rule family=ipv4 source address=192.168.1.0/24 port port=631 protocol=tcp accept' --permanent
sudo firewall-cmd --reload
```

---

### 6. **Sandboxing Print Filters**

* Print filters can be exploited in poorly configured systems
* Enable **filter sandboxing** in `cupsd.conf`:

```apache
Sandboxing Relaxed
```

* For higher security (note: may break some filters):

```apache
Sandboxing Strict
```

#### ➤ Systemd sandboxing (for advanced users):

* Apply `ProtectSystem=full` and `PrivateTmp=yes` in the systemd unit file (`/lib/systemd/system/cups.service`)

---

### 7. **Disable Unused Protocols**

* Disable legacy protocols unless needed:

```apache
BrowseProtocols none
```

* In `/etc/cups/cupsd.conf`, remove:

  * `Listen *:631` → use `Listen localhost:631` or specific interface IP
  * `Browsing On` → turn off mDNS unless you need AirPrint

---

### 8. **Monitoring and Logging**

* View logs:

```bash
journalctl -u cups.service
less /var/log/cups/error_log
```

* Set log level:

```apache
LogLevel warn
```

---

### 9. **Conclusion**

* CUPS is a powerful but sensitive service.
* With PAM, firewalls, HTTPS, and ACLs, you can reduce the risk profile of a home lab or SMB print service.
* In future articles, we’ll cover integrating Fail2Ban and advanced access logging.

---

Would you like this turned into a ready-to-publish Markdown template next?
