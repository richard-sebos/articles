# Customizing Samba Share Sections

I still remember the first time I tried to customize a Samba share section.
It was a simple goal—share a folder full of family pictures with the rest of the household.

It ended up taking me most of a weekend. I tested like crazy, convinced it was working perfectly—until someone else tried to access it and it failed completely.
Looking back, I wish I still had that original `smb.conf` file. I'd love to see what I did wrong (and maybe what I accidentally got right).

---

In the second part of this series, we focused on tightening security in the `[global]` section of the Samba configuration file. That step helped lay a solid foundation for the server as a whole.

Now, in this part, we'll dive into the `[share name]` sections. These are where individual shares are defined—each with its own path, access rules, and optional overrides to the global settings.
This is also where you can fine-tune security and functionality at the share level, giving you precise control over how each resource is accessed and used.


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

