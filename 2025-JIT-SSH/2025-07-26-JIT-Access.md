# Just-in-Time (JIT) SSH Access with a Bastion Host on Proxmox VE

## Introduction

Strong security doesn't have to be complicated. This guide walks through setting up a secure, time-limited SSH access system using a bastion host in a Proxmox Virtual Environment (VE). It combines a few simple tools and practices—network rules, SSH certificates, and a bit of scripting—to give you a flexible and secure way to manage who can access your servers, when, and for how long.

---

## Table of Contents

1. [Introduction](#introduction)
2. [What Are JIT Credentials?](#what-are-jit-credentials)
3. [How the System Works](#how-the-system-works)
4. [Setting Things Up](#setting-things-up)

   * [Creating the Bastion Host](#creating-the-bastion-host)
   * [Network Segmentation & Firewall Rules](#network-segmentation--firewall-rules)
   * [User Roles & Access](#user-roles--access)
   * [Setting Up SSH Certificate Authority](#setting-up-ssh-certificate-authority)
5. [Managing Access with a Simple App](#managing-access-with-a-simple-app)
6. [Access Logging & Reports](#access-logging--reports)
7. [Why This Helps Security](#why-this-helps-security)
8. [Is This Overkill?](#is-this-overkill)
9. [Final Thoughts](#final-thoughts)

---


## What Are JIT Credentials?

Just-in-Time (JIT) credentials let you grant temporary access to a system only when it's needed—say, to fix an issue or run an update. The key idea is that credentials are short-lived, so they can’t be reused later. This makes it much harder for attackers to gain long-term access, even if a credential leaks.

In this setup, a bastion host controls access to your Proxmox virtual machines. Only approved users, using a one-time certificate and multi-factor authentication (MFA), can get in—and only for a short time.

---

## How the System Works

At the center is a “bastion” or “jump” server—essentially a secure checkpoint. Your personal devices (like your laptop) connect only to this bastion, which then allows controlled access to the rest of your environment.

👉 If you want a deeper dive into setting up a bastion host, check out this [guide on jump servers](https://richard-sebos.github.io/sebostechnology/posts/Jump-Server/).

Here’s what controls access:

* **Firewall rules**: Only specific devices (like your laptop) can reach the bastion.
* **User roles**: Accounts are split between regular and admin duties.
* **SSH certificate authority**: You issue short-lived SSH certificates instead of using long-lived keys.
* **MFA**: Access requires a time-based code from your phone.
* **Python script**: This handles MFA and certificate generation.

---

## Setting Things Up

### Creating the Bastion Host

Spin up a minimal Linux VM (like Oracle Linux 9) on your Proxmox server. This VM becomes your bastion—your secure entry point into the rest of the network.

More details on building this out here:
👉 [How to set up a jump server](https://richard-sebos.github.io/sebostechnology/posts/Jump-Server/)

### Network Segmentation & Firewall Rules

I use OpnSense to set up VLANs: one for my home devices and one for the virtual machines. The firewall only allows my laptop to talk to the bastion host, keeping everything else out.

### User Roles & Access

Two user accounts help separate duties:

* `richard`: A limited user who’s allowed to log in over SSH.
* `admin_richard`: An admin user with full privileges, but no SSH login.

This keeps privilege escalation under control.
👉 [Guide: Creating users with restricted access](https://richard-sebos.github.io/sebostechnology/posts/Restricted-Access/)

### Setting Up SSH Certificate Authority

Instead of juggling tons of SSH keys, I created a Certificate Authority (CA) using OpenSSH. The bastion only accepts connections from certificates signed by this CA—and certificates are only valid for a few minutes.

👉 Here’s a full breakdown on [time-limited SSH access using OpenSSH certificates](https://richard-sebos.github.io/sebostechnology/posts/OpenSSH-Cert-SSH-Keys/)

---

## Managing Access with a Simple App

I built a lightweight Python script that handles everything:

1. The user runs the app and enters their password and MFA code.
2. They provide a short reason for needing access.
3. The app generates a short-lived SSH certificate (e.g., 15 minutes).
4. It uses the short-lived SSH certificate to automatically establish a secure SSH connection to the bastion box.

Once logged in, sessions remain active, but the user can’t log in again after the certificate expires—keeping things secure without being annoying.

---

## Access Logging & Reports

The app also keeps a log of who requested access, when, and why. These logs can be extended to feed into external tools like Wazuh, ELK, or Graylog for full visibility. But even on its own, this gives you basic tracking and accountability.

---

## Why This Helps Security

Before this system, my laptop held all my SSH keys. If I lost it, someone could get into every server I managed.

Now, the bastion is the only way in. And even then, you need:

* The CA private key (which stays safe),
* A valid password,
* A time-sensitive MFA code,
* And access to a specific device (my laptop).

Even if someone grabs a key or steals a device, it’s useless without the rest of the puzzle—and even then, the access window is tiny.

[See code here](https://github.com/richard-sebos/sebostechnology/tree/main/assets/code/jit)

---

## Is This Overkill?

Maybe. But labs tend to grow into something more complex over time.

This setup may seem like a lot for a homelab—but it’s reusable, scalable, and actually mirrors what many businesses use. More importantly, it’s a good habit: build with security in mind from the start, so you don’t have to fix it later.

And when something *almost* goes wrong, you’ll be glad you did.

---

## Final Thoughts

Combining SSH certificates, MFA, network segmentation, and role-based access gives you a surprisingly strong security foundation. It doesn’t take a ton of time, and once it’s set up, it mostly runs itself.

Whether you're tinkering in a homelab or managing a small business environment, this setup helps keep your systems safe—without getting in your way.
