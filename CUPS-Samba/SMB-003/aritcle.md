# 🧱 Legacy 3 – *Samba Share Isolation: When Every Folder Has Its Own Policy*

### 🎯 Objective

- I remember trying to customized my first Samba share section.  
- It was to share family pictures with the rest of the family.
- It took me most of a weekend and tested like crazy.
- It work great for me and as soon as I had someone else try it, it fail.
- I wish had that config file today to see what I did wrong.


In the second part of this series, we added additional security to a Samba server at the `[global]` level. It continued the building of the server. 
The `[share name]`  section also change have security changes made to it. This allows for each share to have additional options that extend or override the `[global]` setup.

---

## 1. Introduction: The Root of Trust Lives in `[share name]`

Samba’s config file (`smb.conf`) is split into two main blocks:

* **[global]** — sets server-wide defaults and policies
* **[share]** — configures individual shares, and can override `[global]` settings as needed

Why have both? The `[global]` section lets you define a consistent baseline that applies across all shares. This makes it easier to manage multiple Samba servers and keep your security posture uniform. Then, for those special cases, the `[share name]` sections let you tighten or loosen access for individual shares.

---

## 🗂️ Shares Name
- 













### 1. Introduction – “Global Defines Policy, Shares Define Reality”

* Explain inheritance and override hierarchy.
* Emphasize least privilege per share.
* ProofTrail concept: “Each share can have its own trust boundary.”

### 2. Step 1 – Review Global Defaults

* Quickly show `[global]` recap and how they cascade.
* Explain which directives can be overridden per share.

### 3. Step 2 – Create a Secure Share

```ini
[finance]
   path = /srv/samba/finance
   read only = no
   valid users = @finance
   browseable = no
   create mask = 0660
   directory mask = 0770
   force group = finance
```

* Explain each directive’s security role.
* Demonstrate permission alignment with `ls -ld`.

### 4. Step 3 – Public or Guest Shares (Cautious Isolation)

```ini
[public]
   path = /srv/samba/public
   guest ok = yes
   read only = yes
   browseable = yes
```

* Show containment through file permissions.
* Discuss network segmentation for guest shares.

### 5. Step 4 – Validate Access

```bash
smbclient -L localhost -U user
smbclient //localhost/finance -U user
```

* Use examples showing denied vs permitted access.
* Log events from `/var/log/samba/log.<client>`.

### 6. Step 5 – Apply Share-Specific Logging

* Configure per-share logs:

  ```ini
  log file = /var/log/samba/log.%m
  ```
* Explain how this supports accountability.

### 7. Step 6 – Automate Testing

* Use a small bash script to verify access levels per share.
* Future tie-in: automate this under ProofTrail’s audit chain.

### 8. Lessons Learned

* Every share is its own containment cell.
* Overlapping permissions create ambiguity — clarity is protection.

### 🧩 ProofTrail Note

> “Each share adds a new layer to your audit trail. ProofTrail turns these layers into verifiable checkpoints.”

---




   🔍 Auditing Access

Enable audit logging for Samba share access:

vfs objects = full_audit

Example:
vfs objects = full_audit
full_audit:prefix = %u|%I|%S
full_audit:success = open opendir
full_audit:failure = none
full_audit:facility = LOCAL7
full_audit:priority = NOTICE
   
valid users = @finance, alice
invalid users = root

    path = /srv/samba/sales
    browsable = no
    writable = yes
    valid users = @salesgroup
    force group = salesgroup
    create mask = 0660
    directory mask = 0770
    vfs objects = full_audit
    hosts allow = 192.168.10.0/24
hosts deny = 0.0.0.0/0

