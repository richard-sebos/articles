---
layout: post
title: "Using a Jump Server and SSH ProxyJump in Your Homelab"
date: 2025-06-29 08:00:00 +0000
categories: [Linux, Networking, Security]
tags: [linux, ssh, jump-server, bastion, homelab]
image:
  path: /assets/img/JumpServer.png
  alt: Jump Server 
description: >-
  Secure your homelab with a jump server and SSH ProxyJump. This guide walks through setting up a bastion host, generating SSH keys, and configuring SSH access for internal VMs.
---

### What Is a Jump Server (or Bastion Host)?

If you're running multiple Linux servers in your homelab or a small network, having a **centralized way to access them** can save a lot of time and improve security. This is where a **jump server**—also called a **bastion host**—comes into play.

A jump server acts as a secure gateway between your workstation and your internal systems. Instead of connecting to each server individually, you log into the jump server first, and then access other machines from there. This setup not only streamlines management but also adds a layer of security by exposing only one public-facing system instead of many.

Many homelab users also use their jump server as a lightweight repository to store scripts, configuration backups, or documentation. This keeps everything organized and accessible in one place.

While the terms are often used interchangeably, "bastion host" is more common in cloud environments like AWS or Azure, whereas "jump box" or "jump server" is often used in smaller, on-premises setups.

---

### Why Use a Jump Server?

The main benefit is **security**. Rather than allowing direct SSH access to every server in your network, you only expose the jump server. All internal machines stay private and are only accessible through this single point. This limits the potential attack surface and makes it easier to monitor and control access.

It also improves operational efficiency by letting you manage all systems from one trusted point, while supporting things like key-based authentication and centralized logging.

---

### SSH ProxyJump: Secure Routing Through a Jump Host

To connect to internal systems via the jump server, we'll use an SSH feature called **ProxyJump**, which routes traffic through an intermediate host.

To keep things clean and secure, we'll generate two SSH keys—one for the jump server and one for the internal VM:

```bash
# Key for internal VM
ssh-keygen -t ed25519 -f ~/.ssh/vm

# Key for bastion host
ssh-keygen -t ed25519 -f ~/.ssh/bastion
```

Using separate keys makes it easier to manage access and rotate keys if needed.

---

### Setting Up the Bastion Host

Start with a minimal Linux install and harden it by:

* Disabling root login via SSH.
* Disabling password-based logins.
* Creating a non-root user with sudo access.
* Installing your SSH public key into `~/.ssh/authorized_keys`.
* Adding basic security tools like `fail2ban` or `ufw`.

Your bastion should sit in a DMZ or a network zone that can reach internal systems but is locked down from the public internet.

---

### Connecting via SSH Jump

You can quickly connect to an internal system using the `-J` option:

```bash
ssh -J bastion_user@bastion_ip vm_user@vm_ip
```

But for frequent use, configuring SSH access in `~/.ssh/config` is cleaner.

#### Example Config Setup

**File: \~/.ssh/include.d/bastion**

```ini
Host bastion
    HostName 203.0.113.10
    User gateway
    IdentityFile ~/.ssh/bastion
```

**File: \~/.ssh/include.d/vm**

```ini
Include ~/.ssh/include.d/bastion
Host internal-vm
    HostName 10.0.0.20
    User admin
    ProxyJump bastion
    IdentityFile ~/.ssh/vm
```

**Main Config: \~/.ssh/config**

```ini
Include ~/.ssh/include.d/bastion
Include ~/.ssh/include.d/vm
```

Now, connecting is as easy as:

```bash
ssh internal-vm
```

> **Pro Tip:** Organizing SSH configs with `Include` files makes it easier to manage multiple environments—perfect for homelabs or consulting work.

---

### Security Advantages of This Setup

Using `ProxyJump` with a jump server improves security by:

* Preventing direct access to internal systems.
* Using different keys for different roles.
* Allowing you to monitor and control all access from a single point.
* Making attackers go through multiple secured layers to reach your VMs.

---

### Is This Bulletproof?

No system is hack-proof. But this setup raises the bar significantly. An attacker would need to:

* Access a trusted network or VPN.
* Compromise the jump server.
* Possess both SSH keys and know usernames and IPs.

That’s a lot harder than attacking a single exposed VM.

---

In short, a jump server is a smart, simple way to improve your homelab’s security and organization—especially as you scale to multiple servers or VMs.

---
**Need Linux expertise?** I help businesses streamline servers, secure infrastructure, and automate workflows. Whether you're troubleshooting, optimizing, or building from scratch—I've got you covered.  
📬 Drop a comment or [email me](mailto:info@sebostechnology.com) to collaborate. For more tutorials, tools, and insights, visit [sebostechnology.com](https://sebostechnology.com).