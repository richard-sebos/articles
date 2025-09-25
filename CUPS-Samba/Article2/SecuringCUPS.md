Absolutely — here’s a detailed **outline and command reference** for your article:



---
Start of securing users
If you're trying to **limit remote access to the CUPS web interface** *only to specific users*, and you're not using system accounts (or want extra control), then **CUPS password files** can be a good solution — *if used correctly*.

Let’s break down:

---

## 🔐 How Secure Are CUPS Password Files?

CUPS supports two types of password files:

* **Basic Authentication** (`AuthType Basic`) – often tied to **system users**
* **Digest Authentication** (`AuthType Digest`) – uses **separate password file**, more secure than Basic

### 🔍 Digest vs Basic Auth:

| Feature                            | Basic Auth                                        | Digest Auth                                               |
| ---------------------------------- | ------------------------------------------------- | --------------------------------------------------------- |
| Security                           | Password sent base64-encoded (can be intercepted) | Password hashed with challenge-response (safer over HTTP) |
| System account required?           | Usually yes                                       | No, can use isolated password file                        |
| Compatible with HTTPS              | Yes                                               | Yes                                                       |
| Usable without system shell/login? | Yes (with config)                                 | Yes                                                       |
| Default storage                    | `/etc/shadow` or external file                    | Custom file like `/etc/cups/passwd.digest`                |

➡️ **Digest Auth is significantly more secure than Basic**, especially over **unencrypted HTTP**.
Over HTTPS, both are acceptable, but **Digest is still safer if HTTPS is not used.**

---

## ✅ Secure Setup Using Digest Auth (Recommended)

### 🔧 Step-by-Step:

1. **Create a secure digest password file:**

```bash
sudo touch /etc/cups/passwd.digest
sudo chmod 600 /etc/cups/passwd.digest
sudo htdigest /etc/cups/passwd.digest CUPS username1
```

* `CUPS` = authentication realm (must match in config)
* This will prompt for a password (stored as an MD5 hash)

2. **Edit your `/etc/cups/cupsd.conf`:**

```conf
Listen 192.168.1.10:631

<Location />
  Order allow,deny
  Allow from 192.168.1.0/24
  Deny from all
  AuthType Digest
  AuthClass User
  AuthUserFile /etc/cups/passwd.digest
  AuthDigestDomain /
  Require user username1 username2
</Location>

WebInterface Yes
```

> 🔒 You can further restrict `<Location /admin>` separately if you want different rules for print browsing vs. admin actions.

3. **Restart CUPS:**

```bash
systemctl restart cups
```

---

## 🚧 Additional Security Considerations

### 1. **Use HTTPS (TLS)**

Digest Auth is better than Basic over HTTP, but still: **Enable HTTPS** if at all possible.

In `cupsd.conf`:

```conf
DefaultEncryption Required
```

This forces HTTPS and disables plain HTTP.

Ensure `/etc/cups/ssl` contains valid TLS certs (you can use Let's Encrypt or self-signed).

### 2. **File Permissions**

```bash
chmod 600 /etc/cups/passwd.digest
chown root:lp /etc/cups/passwd.digest
```

Ensure only `cupsd` or root can read it.

### 3. **Audit Access Attempts**

Monitor access via:

```bash
journalctl -u cups
# or
grep 'Unauthorized' /var/log/cups/error_log
```

Set `LogLevel info` or `debug2` temporarily for troubleshooting.

---

## 🛡️ In Summary

| Security Area          | Recommendation                                         |
| ---------------------- | ------------------------------------------------------ |
| Auth method            | Use `AuthType Digest`                                  |
| Password file location | Store outside webroot, e.g., `/etc/cups/passwd.digest` |
| Permissions            | 600, owned by root or cups                             |
| Interface exposure     | Bind to specific IPs (not `Port 631`)                  |
| Network access         | Restrict via firewalld and `Allow from`                |
| Encryption             | Enable TLS via `DefaultEncryption Required`            |
| Audit                  | Watch logs for failed auth or brute force attempts     |

---

### 🚀 Want: A ready-to-use hardened `cupsd.conf` template with digest auth for remote access?

I can generate one tailored to:

* Your IP range (e.g., `192.168.1.0/24`)
* Authorized users
* TLS enabled or not

Let me know!


To **add a user for CUPS Digest authentication**, you **do NOT need to create a system (Linux) user**. Instead, you create a user in a CUPS-specific password file using the `htdigest` utility.

Here’s how to do it step-by-step.

---

## 🔐 Add a User for CUPS Digest Auth

### 📍 1. **Choose or Create the Password File**

Let’s say you’ll use:

```bash
/etc/cups/passwd.digest
```

> If the file doesn’t exist yet, `htdigest` will create it.

---

### 🛠️ 2. **Run `htdigest` to Add the User**

Syntax:

```bash
htdigest /path/to/passwordfile realm username
```

Example:

```bash
sudo htdigest /etc/cups/passwd.digest CUPS printuser1
```

* `CUPS` is the **realm** — must match the one used in your `cupsd.conf`
* `printuser1` is the user you want to add
* You’ll be prompted for a password (used when logging into the web UI)

> You can repeat this to add more users.

---

### 🔁 3. **Update `cupsd.conf`**

Example config block to use digest auth with these users:

```conf
<Location />
  Order allow,deny
  Allow from 192.168.1.0/24
  Deny from all
  AuthType Digest
  AuthClass User
  AuthUserFile /etc/cups/passwd.digest
  AuthDigestDomain /
  Require user printuser1 printuser2
</Location>
```

> Make sure `AuthUserFile` points to the correct file, and `Require user` lists the usernames.

---

### 🔄 4. **Restart CUPS**

```bash
sudo systemctl restart cups
```

---

### 🔍 5. **Test the Login**

* Open a browser and go to: `https://<cups_server_ip>:631`
* You should be prompted for a username/password
* Only listed users in `/etc/cups/passwd.digest` can log in

---

## ✅ Good Practices

| Step                        | Command                                                              |
| --------------------------- | -------------------------------------------------------------------- |
| Secure the file             | `chmod 600 /etc/cups/passwd.digest`                                  |
| Limit access to root & CUPS | `chown root:lp /etc/cups/passwd.digest`                              |
| View current users          | `cat /etc/cups/passwd.digest` (usernames in first field)             |
| Remove a user               | Manually edit the file with `vi` or use `htdigest -c` to recreate it |

---

Let me know if you want a script or Ansible task to automate adding these users securely.


---



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
