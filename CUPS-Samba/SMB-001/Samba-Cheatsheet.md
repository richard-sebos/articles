# 🧰 Samba Admin Cheatsheet for Oracle Linux 9

> *Quick reference for troubleshooting, securing, and validating Samba shares on Oracle Linux 9. This cheatsheet complements the [main setup guide](./samba-on-oracle-linux-9.md), providing fast answers when you’re deep in the trenches.*

---

## 🔧 Troubleshooting Quick Reference

| Error                        | Common Cause         | Fix                                                   |
| ---------------------------- | -------------------- | ----------------------------------------------------- |
| `NT_STATUS_BAD_NETWORK_NAME` | Incorrect share name | Check `[ShareName]` in `smb.conf`                     |
| `NT_STATUS_ACCESS_DENIED`    | Wrong user or perms  | Ensure user/group permissions and `valid users` match |
| Cannot access share          | SELinux or firewall  | Check file contexts and port access                   |

Check Samba logs in real time:

```bash
sudo tail -f /var/log/samba/log.smbd
```

---

## 🛡️ Security Considerations

| Security Concern    | Best Practice                                           |
| ------------------- | ------------------------------------------------------- |
| Guest Access        | Disable in production; always use authenticated users   |
| SELinux Contexts    | Use `samba_share_t` for shared directories              |
| Firewall Zones      | Restrict Samba services to trusted interfaces/networks  |
| SMB Version Control | Set `min protocol = SMB2` in `[global]`                 |
| User Access Control | Use `valid users`, groups, and `chmod` to manage access |

---

## ✅ Test Checklist

| Test Type            | Command                                          |
| -------------------- | ------------------------------------------------ |
| Verify share visible | `smbclient -L //<server-ip>`                     |
| Connect anonymously  | `smbclient //<server-ip>/Shared -U guest`        |
| Connect with user    | `smbclient //<server-ip>/SecureShare -U smbuser` |
| View Samba logs      | `sudo tail -f /var/log/samba/log.smbd`           |

---

## 🧾 Samba Service Commands

```bash
# Start/stop/restart Samba
sudo systemctl start smb
sudo systemctl stop smb
sudo systemctl restart smb

# Check configuration syntax
testparm

# List available shares
smbclient -L localhost -U%

# Connect to a specific share
smbclient //localhost/SecureShare -U smbuser
```

---

## 📚 Related Resources

* [Samba Official Documentation](https://www.samba.org/samba/docs/)
* [Red Hat: SELinux and Samba](https://access.redhat.com/solutions/205733)
* [Oracle Linux Samba Guide](https://docs.oracle.com/en/)
* [Main Setup Guide (This Series)](./samba-on-oracle-linux-9.md)

---

## 🧭 Wrap-Up

This cheatsheet is designed to be your **fast-access toolkit** when working with Samba—whether you're troubleshooting a failed connection or validating a secure configuration.

For full installation instructions and share setup details, head back to the main article:

👉 [**Samba on Oracle Linux 9: Secure File Sharing for Mixed Environments**](./samba-on-oracle-linux-9.md)

