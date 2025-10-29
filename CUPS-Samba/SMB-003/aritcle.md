# Customizing Samba Share Sections

I still remember the first time I tried to customize a Samba share section.
The goal was simple—share a folder full of family pictures with the rest of the household.

It ended up taking most of a weekend. I tested it like crazy and was convinced it was working perfectly—until someone else tried to access it... and it failed completely.
Looking back, I wish I still had that original `smb.conf` file. I'd love to see what I did wrong (and maybe what I accidentally got right).

---

In the second part of this series, we focused on tightening security in the `[global]` section of the Samba configuration file. That step helped us lay a solid foundation for the server as a whole.

Now in this part, we're going to focus on the `[share name]` sections. These define the individual shares—each with its own path, access rules, and options.
Here, you can fine-tune access control and functionality at a per-share level, including overrides to `[global]` settings for more granular control.

---

## 🗂️ Defining Shares

A Samba server’s `smb.conf` file can contain one or more *share definitions* (also known as *share blocks* or *sections*).
Share allows you to expose a directory (or printer) to the network and define how it should behave.

Each share:

* Starts with a name in square brackets (e.g., `[sharename]`)
* Requires at minimum a `path` directive
* Can include various permissions and security options

Here’s an example where we define shares for home lab projects and family pictures:

```ini
[home_lab_projects]
path = /srv/samba/hl_projects

[family_pictures]
path = /srv/samba/family_pictures
```

---

## 👥 Controlling Share Access

Let’s define who can access each share using `valid users` and `invalid users`.

* A group named `family` was created to allow family members to access the picture share:

  * `valid users = @family`
* You can also specify users outside of a group—e.g., adding `alice` directly:

  * `valid users = @family alice`
* A separate group, `project_users`, manages access to the home lab project share:

  * `valid users = @project_users`
* Allowing `root` access to shares over the network is a known security risk.

  * Even if `root` isn’t in these groups, it’s best to explicitly deny:

    * `invalid users = root`

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

---

## 🔐 Read-Only, Writable, and Browsable

These options control how a share can be used and whether it appears in network browse lists.

* **Family pictures** should be protected against deletion or modification:

  * `read only = yes`
* **Project files** need full read/write access:

  * `writable = yes`
* To reduce visibility and attack surface, both shares are hidden from casual browsing:

  * `browsable = no`

```ini
[home_lab_projects]
path = /srv/samba/hl_projects
valid users = @project_users
invalid users = root
browsable = no
writable = yes

[family_pictures]
path = /srv/samba/family_pictures
valid users = @family alice
invalid users = root
browsable = no
read only = yes
```

---

## 🌐 Restricting Network Access

We previously defined `hosts allow = 192.168.35.0/24` in the `[global]` section.
This applies to all shares unless overridden.

* The family pictures share will inherit this and remain accessible to the entire subnet.
* For the project share, we want tighter restrictions—only allowing specific IPs:

```ini
[home_lab_projects]
path = /srv/samba/hl_projects
valid users = @project_users
invalid users = root
browsable = no
writable = yes
hosts allow = 192.168.35.110 192.168.35.111
```

---

## 🛠️ Masks, Force User, and Force Group

When users create files or directories via Samba, permissions and ownership need to be controlled to ensure consistency and prevent privilege issues.

* **`create mask`** sets file permissions on new files.
* **`directory mask`** sets permissions on new directories.
* **`force group`** and **`force user`** ensure that created files are owned by a specific group/user.

We apply these to the project share to enforce group ownership and standard access rights.
Since the family pictures share is read-only, these settings aren’t needed there.

```ini
[home_lab_projects]
path = /srv/samba/hl_projects
valid users = @project_users
invalid users = root
browsable = no
writable = yes
hosts allow = 192.168.35.110 192.168.35.111
force group = project_users
create mask = 0660
directory mask = 2770
```

---

## ✅ Summary

The difference between a simple setup and this more secure configuration isn’t a huge amount of work—but it **does** add several important layers of protection:

* Shares are hidden (`browsable = no`) and user access is restricted
* Family pictures are read-only and protected from deletion or modification
* Home lab projects can only be accessed from specific trusted devices
* Root access is explicitly blocked from both shares

That said, **if you’re storing sensitive documents**, it’s always a good idea to **encrypt** them at rest—even inside a private share.

You never know when the most secure system becomes vulnerable due to a **zero-day exploit**.

