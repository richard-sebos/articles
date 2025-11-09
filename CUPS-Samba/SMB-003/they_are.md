---
title: Customizing Samba Share Sections – Fine-Tune Access, Visibility, and Security
subtitle: Take Control of Individual Shares with Precise Permissions, IP Restrictions, and User-Based Access Rules
date: 2025-10-27 09:30 +0000
categories: [Linux, Infrastructure]
tags: [Samba, SMB, OracleLinux, FileSharing, LinuxAdmin, Security]
image:
  path: /assets/img/Samba_Share_Sections.png
  alt: Secure Samba share section configuration on Oracle Linux with controlled access and masked permissions
---


If you're setting up Samba shares, you’re probably aiming for something deceptively simple—**“I just want to share a folder.”**

But like many IT pros (myself included), you’ve likely hit a moment where things *almost* worked… until they didn’t.

That’s why this guide exists—to help **you** skip the guesswork, avoid trial-by-fire debugging, and set up share sections that are **secure, reliable, and customized for your environment**.

---

In the last part of this series, **you hardened the `[global]` section**, laying the groundwork for a trustworthy Samba server.

Now it’s time to **take full control of the `[share name]` sections**—where the real power lies. These define how each folder behaves on your network, including access control, permissions, and visibility.

---

## 🗂️ Step 1: Define the Shares You Need

Every Samba share begins its life in `smb.conf` with a section header (e.g., `[myshare]`) and a `path`.

You decide which folders should be shared—and how:

```ini
[home_lab_projects]
path = /srv/samba/hl_projects

[family_pictures]
path = /srv/samba/family_pictures
```

With just a few lines, you’ve now made two folders shareable across your network. But **the real customization comes next**.

---

## 👥 Step 2: Control Who Can Access What

You're the gatekeeper here—so you get to define **who can access each share**:

* Want to share the family photos? Use a group like `@family`.
* Need tighter controls on project files? Assign access to `@project_users`.
* Don’t forget to block `root`, even if not explicitly included—it’s a smart security move.

```ini
[home_lab_projects]
path = /srv/samba/hl_projects
valid users = @project_users
invalid users = root

[family_pictures]
path = /srv/samba/family_pictures
valid users = @family alice
invalid users = root
```

You’ve just added a security layer that protects your data *before* any user touches it.

---

## 🔐 Step 3: Set Permissions for Read, Write, and Visibility

You define how each share behaves—whether it’s visible on the network and whether it’s writable.

Let’s align each share with its purpose:

* 🖼️ **Family pictures**: Set to `read only = yes` to prevent accidental deletion.
* 🧪 **Home lab projects**: Enable `writable = yes` for full access.
* 🤫 **Both shares**: Use `browsable = no` to hide them from casual discovery.

```ini
[home_lab_projects]
...
browsable = no
writable = yes

[family_pictures]
...
browsable = no
read only = yes
```

You’re not just sharing folders—you’re building intentional access boundaries.

---

## 🌐 Step 4: Restrict Access by Network

You've already secured access by user, but **you can go a step further** and limit access to specific IPs.

* 🖼️ The **family share** remains accessible to the whole home subnet.
* 🧪 The **project share** is restricted to specific machines:

```ini
[home_lab_projects]
...
hosts allow = 192.168.35.110 192.168.35.111
```

With this, even if a user has credentials, **they need to be on a trusted device** to gain access.

---

## 🛠️ Step 5: Enforce Permissions with Masks and Force Settings

Now you're fine-tuning file ownership and permissions. This ensures consistent behavior—no surprise permission issues or broken group access.

For shares where users create or modify files (like your project folder), enforce structure with:

```ini
[home_lab_projects]
...
force group = project_users
create mask = 0660
directory mask = 2770
```

You’re shaping how files behave the moment they’re created—without relying on end-user discipline.

---

## ✅ Final Checklist: What You’ve Just Accomplished

By customizing your share sections, **you’ve moved beyond a basic setup** to one that’s:

✔️ Private — hidden from browse lists
✔️ Purpose-driven — writable or read-only based on need
✔️ Secure — with user, group, and IP restrictions
✔️ Consistent — enforcing correct permissions from the start

And most importantly: **You’ve done it right.** This is a setup you can confidently rely on.

---

> 💡 **Pro Tip:** Even with a locked-down Samba config, consider encrypting sensitive data at rest. All it takes is one zero-day exploit for a seemingly safe system to become a target.
