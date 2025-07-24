# Just-in-Time (JIT) SSH Access with a Bastion Host on Proxmox VE

## Table of Contents

1. [Introduction](#introduction)
2. [Understanding JIT Credentials](#understanding-jit-credentials)
3. [System Architecture Overview](#system-architecture-overview)
4. [Setting Up the Environment](#setting-up-the-environment)

   * [Creating the Bastion Host](#creating-the-bastion-host)
   * [Firewall and Network Segmentation](#firewall-and-network-segmentation)
   * [User Access Control](#user-access-control)
   * [SSH Certificate Authority Configuration](#ssh-certificate-authority-configuration)
5. [JIT Access Management Application](#jit-access-management-application)
6. [Generating Access Reports](#generating-access-reports)
7. [Security Benefits and Motivation](#security-benefits-and-motivation)
8. [Is It Overkill?](#is-it-overkill)
9. [Conclusion](#conclusion)

---

## Introduction

One of the advantages of a layered security model is its ability to build a robust system by interconnecting several smaller components without significant complexity. In this article, I aim to combine a few topics I’ve explored recently to develop a Just-in-Time (JIT) credential system for Linux, particularly tailored for use with a bastion host in a Proxmox Virtual Environment (VE). While the solution involves some scripting, the code is straightforward and highly reusable.

---

## Understanding JIT Credentials

Just-in-Time (JIT) credentials provide temporary access to systems only when needed and for a limited time. These credentials are valid just long enough to perform a specific task—such as system setup or applying a hotfix—and then expire. This greatly reduces the attack surface by ensuring that access is granted only on demand, and only under controlled conditions. In this setup, I demonstrate how to implement JIT SSH access using a bastion host that controls entry to virtual machines hosted on a Proxmox VE server. This approach includes role-based user restrictions, multi-factor authentication (MFA), and access logging as part of a broader security policy.

---

## System Architecture Overview

The core of this setup involves a jump host (bastion) that serves as the gatekeeper between external devices (such as my home laptop) and the internal virtual machines in the Proxmox VE environment. Access to the bastion is tightly controlled using firewall rules, restricted user accounts, SSH certificate authorities (CA), and a custom Python application that enforces MFA and temporary credential generation.

---

## Setting Up the Environment

### Creating the Bastion Host

To begin, I provisioned a new virtual machine on my Proxmox VE server, installing Oracle Linux 9 with a minimal configuration. This VM serves as the bastion host for all secure access into the internal network.

### Firewall and Network Segmentation

I implemented firewall rules on my OpnSense gateway to tightly control access to the bastion host. My lab setup includes multiple VLANs—one for my home network (HomeNet) and another for the virtual environment (VMNet). I configured the firewall so that only my laptop on HomeNet can reach the bastion host on VMNet.

### User Access Control

User roles on the bastion host are segregated into two accounts:

* **richard** – A restricted user with SSH login permission.
* **admin\_richard** – An administrative user with sudo privileges but no SSH login access.

This setup ensures that even if the restricted user's credentials are compromised, escalation requires additional security steps.

### SSH Certificate Authority Configuration

To manage secure, time-limited SSH access, I generated a set of OpenSSH keys to act as a Certificate Authority (CA). The public key of this CA was deployed to the bastion host, and SSH server settings were modified to accept client certificates signed by this CA. This provides fine-grained control over who can access the server and for how long.

---

## JIT Access Management Application

To orchestrate access, I developed a lightweight Python application that automates SSH certificate creation and enforces multi-factor authentication.

Before a user can request access, they must set up an MFA token using a mobile authenticator app (e.g., Google Authenticator). The app registers a username and MFA secret, then generates a password for that session.

To initiate a session, the user runs the app, enters their password and current MFA token, and is prompted to explain why access is needed. The app then generates a temporary SSH certificate, valid for a short period (e.g., 15 minutes), and provides a ready-to-use SSH command for connecting to the bastion host.

Importantly, while the certificate is only valid for initial login during that 15-minute window, any active session remains valid until the user logs out. This provides a secure yet functional access experience.

---

## Generating Access Reports

The application also logs access requests, including the user, timestamp, and justification for access. These reports focus on bastion host access only; deeper audit trails can be handled by integrating with external SIEM tools such as Wazuh, ELK Stack, or Graylog. These tools can correlate activity across the internal network to detect unauthorized behavior or policy violations.

---

## Security Benefits and Motivation

Prior to implementing this solution, my home laptop was a single point of failure—it stored all of my SSH private keys, which posed a significant risk. If the laptop were lost or compromised, an attacker could potentially access all my servers.

With the new system in place, the bastion host becomes the only entry point into my environment. Access requires possession of the CA certificate, a valid password, and an MFA token to generate a temporary SSH key. Even if a key is leaked, its short validity period makes it virtually useless to an attacker.

---

## Is It Overkill?

While some may argue that this level of security is excessive for a homelab, labs often evolve into more complex environments over time. The techniques and scripts demonstrated here are scalable and applicable to small business infrastructure as well. Larger enterprises typically use dedicated JIT access solutions, but the underlying principles remain the same.

Security often feels like overkill—until it isn’t. Once a potential breach is thwarted, even the most stringent measures suddenly seem justified. No single layer can stop a determined attacker, but a layered defense can slow them down, create alerts, or even redirect them toward softer targets.

---

## Conclusion

By combining network segmentation, SSH CA authentication, restricted user roles, MFA, and automated certificate issuance, you can create a highly secure, scalable, and manageable JIT access solution. Whether you're protecting a homelab or a business environment, the time spent implementing layered security now will save you from headaches—and potential breaches—later.
