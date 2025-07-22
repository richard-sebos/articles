---
layout: post
title: "Secure SSH Access with Modular Policy Files"
date: 2025-06-15 10:00:00 +0000
author: Your Name
categories: [Linux, Security]
tags: [ssh, hardening, devops, sysadmin]
image:
  path: /assets/img/SSH-Policy-Files.png
  alt: SSH Security Hardening
excerpt: "Hardening your SSH server doesn't have to be complicated. Learn how to use modular policy files with OpenSSH to simplify configuration, improve security, and streamline management."
toc: true
---

## Table of Contents

1. [Introduction](#introduction)
2. [Why SSH Policy Files Matter](#why-ssh-policy-files-matter)
3. [Using `sshd_config` and Include Files](#using-sshd_config-and-include-files)
4. [Policy 1: SSH Connection Limiting](#policy-1-ssh-connection-limiting)
5. [Policy 2: Login Restrictions and Authentication](#policy-2-login-restrictions-and-authentication)
6. [Policy 3: Disable Forwarding and Tunneling](#policy-3-disable-forwarding-and-tunneling)
7. [Policy 4: Secure Environment Variable Handling](#policy-4-secure-environment-variable-handling)
8. [Policy 5: Controlled Access Overrides](#policy-5-controlled-access-overrides)
9. [Conclusion](#conclusion)

---

## Introduction

When it comes to securing SSH, there are plenty of guides and videos focusing on the "first 10 things to change" in your SSH setup. However, this article goes beyond that. We focus on how to group SSH settings into modular, reusable security policy files—providing a flexible and maintainable way to secure your SSH server. By organizing configuration options into purpose-built files, you can enforce security best practices, mitigate known vulnerabilities, and maintain clarity across your server fleet.

---

## Why SSH Policy Files Matter

The default `sshd_config` file is powerful but can quickly become overwhelming due to the breadth of available options. By separating configurations into categorized policy files using the `Include` directive, you create a more readable, maintainable, and scalable SSH configuration system. These smaller, focused files simplify debugging, enhance auditability, and allow selective application of advanced security policies where needed.

---

## Using `sshd_config` and Include Files

OpenSSH’s `sshd_config` supports the `Include` directive, which allows you to load additional configuration files from the `sshd_config.d` directory. This design enables modular configuration—each file can define a specific security policy. Your main `sshd_config` can remain static, while these policy files control detailed behavior.

---

## Policy 1: SSH Connection Limiting

To harden your SSH server against brute-force attacks and vulnerabilities like CVE-2024-6387, this policy enforces strict timeout and connection handling settings.

```bash
## 06-session.conf 
# -----------------------------
# SSH Session Timeout Settings
# -----------------------------

# Sends a "keepalive" message every 300 seconds (5 minutes) to verify the client is still responsive.
ClientAliveInterval 300

# If the client fails to respond to 0 keepalive messages (i.e., first failure triggers disconnect).
# Setting this to 0 means the connection will be closed immediately after the first missed response.
ClientAliveCountMax 0

# Disables TCP keepalive messages at the operating system level to reduce potential detection/exploitation.
TCPKeepAlive no


# -----------------------------
# CVE Mitigation
# -----------------------------

# Set to 0 to immediately drop unauthenticated connections that don't complete login,
# mitigating CVE-2024-6387 (a race condition in login grace handling).
LoginGraceTime 0


# -----------------------------
# Brute-force Mitigation
# -----------------------------

# Limits unauthenticated SSH connection attempts:
# - Allows 3 unauthenticated connections initially.
# - Gradually throttles new connection attempts (up to 30) using a rate of 1 every 10 seconds.
MaxStartups 3:30:10
```

These options reduce idle session time, limit unauthenticated connections, and disable OS-level TCP keepalives.

---

## Policy 2: Login Restrictions and Authentication

This configuration enforces strict user authentication policies and disables insecure login methods. Only users in the `ssh-users` group can log in, and all authentication must be via public keys.

```bash
## 07-authentication.conf
# -----------------------------------------
# Root Access and Group-Based Restrictions
# -----------------------------------------

# Disables direct SSH login as root user to reduce risk of privileged account compromise.
PermitRootLogin no

# Only users belonging to the 'ssh-users' group are allowed to connect via SSH.
# This enables centralized access control using Unix groups.
AllowGroups ssh-users


# -------------------------------
# Basic Authentication Hardening
# -------------------------------

# Prevents users from logging in with empty passwords.
PermitEmptyPasswords no

# Limits the number of authentication attempts per connection to 3.
# Helps prevent brute-force password guessing attacks.
MaxAuthTries 3

# Restricts the number of concurrent open sessions per connection to 2.
# Useful to prevent abuse of multiplexed SSH sessions.
MaxSessions 2


# ----------------------------------------------
# Enforce Key-Based Authentication (No Passwords)
# ----------------------------------------------

# Disables traditional password-based login.
# Only public key authentication will be accepted.
PasswordAuthentication no

# Disables challenge-response (e.g., keyboard-interactive) authentication.
# Further enforces exclusive use of key-based login.
ChallengeResponseAuthentication no


# -------------------------------------
# Enforce Secure File Permissions Checks
# -------------------------------------

# Enables strict checking of user's ~/.ssh and related file permissions.
# Prevents logins if insecure permissions are detected, reducing the risk of key theft.
StrictModes yes

```

These rules also enforce secure file permissions and remove reliance on passwords.

---

## Policy 3: Disable Forwarding and Tunneling

To prevent misuse of SSH tunneling, this policy disables all forms of SSH forwarding—TCP, Unix sockets, agents, X11, and tunnels.

```bash
## 10-forwarding.conf

# ---------------------------------------------
# Disable All SSH Forwarding and Tunneling
# ---------------------------------------------

# Disables TCP port forwarding to prevent users from creating encrypted tunnels
# that could be used to bypass firewalls or access internal services.
AllowTcpForwarding no

# Disables Unix domain socket forwarding (e.g., for interprocess communication).
# Adds an additional layer of restriction for local stream forwarding.
AllowStreamLocalForwarding no

# Prevents forwarding of the SSH authentication agent.
# Protects against credential theft via agent hijacking on shared systems.
AllowAgentForwarding no

# Disables creation of VPN-like tunnels using SSH.
# Helps enforce strict network boundaries and prevent lateral movement.
PermitTunnel no

# Prevents binding forwarded ports to non-loopback addresses (e.g., 0.0.0.0),
# which could expose services to external networks if port forwarding were enabled.
GatewayPorts no

# Disables X11 forwarding to block graphical interface redirection over SSH,
# reducing risk of remote GUI attacks or accidental exposure.
X11Forwarding no
```

This ensures strict session isolation and blocks unauthorized data channels.

---

## Policy 4: Secure Environment Variable Handling

To prevent users from injecting environment variables that could alter session behavior, this policy disables user-controlled environment configuration.

```bash
##99-hardening.conf
# ------------------------------------------------------------
# Disable User-Controlled Environment Variables
# ------------------------------------------------------------

# Prevents users from setting environment variables via ~/.ssh/environment
# or through SSH commands, which could be exploited to alter execution behavior,
# bypass security policies, or inject malicious settings.
PermitUserEnvironment no

```

This reduces the risk of privilege escalation or command manipulation.

---

## Policy 5: Controlled Access Overrides

Sometimes specific users or groups need exceptions. This policy restricts access to trusted IP ranges while relying on firewalls for final enforcement.

```bash
# 08-access-control.conf
## 08-access-control.conf
## Login Overrides
# -----------------------------------------------
# SSH Access Control by IP Address or Subnet
# -----------------------------------------------

# Allow SSH access **only** from trusted internal networks:
# - 192.168.100.0/24: typical internal subnet
# - 10.0.0.0/8: private network range
# Only members of the 'ssh-users' group from these IP ranges will be allowed.
Match Address 192.168.100.0/24,10.0.0.0/8
    AllowGroups str-ssh-users

# -------------------------------------------------------
# Optional: Apply additional restrictions to specific IPs
# -------------------------------------------------------

# Uncomment and customize to enforce stricter rules per host or IP.
# For example, enforce no root login and key-based authentication only
# for a specific host (192.168.100.50):
#
# Match Address 192.168.100.50
#     PermitRootLogin no
#     PasswordAuthentication no

# ------------------------------------------------------------------
# Note: Denying access from all other IPs is **not** handled here.
# ------------------------------------------------------------------
# sshd_config does not support a "deny all except" approach.
# To block untrusted IPs, use a firewall (e.g., firewalld, nftables, or iptables)
# to explicitly allow known IPs and drop everything else at the network level.

```

Use this approach to apply conditional access policies without compromising the core configuration.

---

## Conclusion

Modular SSH security policy files simplify the configuration and management of secure SSH servers. By leveraging OpenSSH’s `Include` directive, you can enforce strong authentication, restrict risky features, and apply custom access controls—all while keeping your configuration clean and maintainable. Start with a solid base policy and extend it with modular, reusable files to achieve flexible, scalable SSH hardening.

