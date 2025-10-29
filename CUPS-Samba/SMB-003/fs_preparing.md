# 🛠️ Preparing the System for Samba Secure Shares

This document outlines the system-level setup steps required to support the secure Samba shares discussed in the main article. This includes group/user creation, directory permissions, and the final `smb.conf` example for reference.

---

## 👥 User and Group Setup

To control access to shares, we start by creating user groups and assigning appropriate ownership and permissions.

### 🔐 Family Share Setup

```bash
# Create a group for family members
sudo groupadd family

# Create the shared directory
sudo mkdir -p /srv/samba/family_pictures

# Assign group ownership
sudo chown -R root:family /srv/samba/family_pictures

# Set group permissions with sticky bit
sudo chmod 2770 /srv/samba/family_pictures

# Add a specific user (e.g., alice)
sudo useradd alice

# Grant alice access to the folder using ACL
sudo setfacl -m u:alice:rwx /srv/samba/family_pictures
```

> 💡 The `chmod 2770` command ensures that new files inherit the group ownership of the directory (`2` sets the setgid bit).
> The `setfacl` command grants `alice` access even if she isn’t part of the `family` group.

---

### 🔧 Project Share Setup

```bash
# Create a group for project users
sudo groupadd project_users

# Create the project directory
sudo mkdir -p /srv/samba/hl_projects

# Assign group ownership
sudo chown -R root:project_users /srv/samba/hl_projects

# Set group permissions with sticky bit
sudo chmod 2770 /srv/samba/hl_projects
```

---

## ⚙️ Example: `/etc/samba/smb.conf`

Below is a secure `smb.conf` configuration that includes:

* SMB3 protocol enforcement with encryption and signing
* User/group-based access control
* Network-level restrictions
* Centralized systemd logging

```ini
[global]
   ## Enforce SMB3 and enable encryption
   server min protocol = SMB3
   server max protocol = SMB3_11
   smb encrypt = required
   server signing = mandatory
   client signing = mandatory

   ## Restrict guest and anonymous access
   security = user
   passdb backend = tdbsam
   map to guest = never
   restrict anonymous = 2

   ## Logging to system journal
   log level = 2 auth:3 vfs:3
   logging = systemd

   ## Allow only trusted subnet
   hosts allow = 192.168.35.0/24
   hosts deny  = ALL

   ## Define workgroup
   workgroup = WORKGROUP

[family_pictures]
   path = /srv/samba/family_pictures
   valid users = @family alice
   invalid users = root
   browsable = no
   read only = yes

[home_lab_projects]
   path = /srv/samba/hl_projects
   valid users = @project_users
   invalid users = root
   browsable = no
   writable = yes
   hosts allow = 192.168.35.110 192.168.35.22
   force group = project_users
   create mask = 0660
   directory mask = 2770
```

---

## ✅ Summary

This setup ensures:

* **Group-based access control** for both shares
* **Encrypted and signed traffic** over the SMB3 protocol
* **Restricted access** based on IP and user identity
* **Hidden shares** that reduce exposure to enumeration
* **Logging integrated with systemd** for easier auditing
* **Consistent permissions** through `create mask` and `force group`

For environments where **data sensitivity is a concern**, consider adding encryption at rest using filesystem-level tools (e.g., `ecryptfs`, `LUKS`, or `encfs`) in addition to Samba's transport encryption.

