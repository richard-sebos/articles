# 🧱 Legacy 3 – *Samba Share Isolation: When Every Folder Has Its Own Policy*

### 🎯 Objective

Teach how to enforce fine-grained security at the **share level**, creating “micro-containment zones” for different data domains.

---

## 🗂️ Outline

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

