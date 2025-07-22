---
layout: post
title: "Stop Reusing Old SSH Keys: How to Use a Signing CA for Expiring SSH Auth"
date: 2025-07-13 10:00:00 +0000
description: "Learn how to protect your Linux servers using OpenSSH Signing CAs and expiring SSH authentication keys. Short-lived SSH keys improve security and minimize attack surfaces."
categories: [Linux, Security]
tags: [SSH, OpenSSH, Security, Linux, DevOps, Infrastructure, Certificates]
image:
  path: /assets/img/CA-Signed-SSH-Auth.png
  alt: "Expiring SSH keys with OpenSSH Signing CA"
---
## **Introduction to SSH Authentication Keys**

SSH keys are simple to create and are usually one of the first tools Linux administrators learn to use. They provide a secure, passwordless method to access remote servers by pairing a private key on the local machine with a public key stored on the server. However, a key limitation is that traditional SSH keys, generated using tools like `ssh-keygen`, do not expire. If a private key is compromised, an attacker could gain persistent access to any server where the public key is authorized. This makes it important to find ways to limit the lifespan of SSH keys to reduce potential security risks.

---

# **Table of Contents**

1. [Introduction to SSH Authentication Keys](#introduction-to-ssh-authentication-keys)
2. [Security Issues with SSH Authentication](#security-issues-with-ssh-authentication)
3. [Creating Expiring SSH Keys with a Signing CA](#creating-expiring-ssh-keys-with-a-signing-ca)

   * [Step 1: Create a Signing CA Key](#step-1-create-a-signing-ca-key)
   * [Step 2: Configure the Remote Server](#step-2-configure-the-remote-server)
   * [Step 3: Generate and Sign User SSH Keys](#step-3-generate-and-sign-user-ssh-keys)
4. [Why Use Expiring SSH Keys?](#why-use-expiring-ssh-keys)
5. [Just in Time (JIT) Logins for SSH](#just-in-time-jit-logins-for-ssh)
6. [Conclusion](#conclusion)

---

## **What is a Signing CA for SSH?**

A **Signing Certificate Authority (CA)** is a trusted entity that can sign SSH public keys to create short-lived certificates. Instead of relying solely on static public keys, the SSH server trusts the CA to vouch for a user's identity for a limited time. These signed certificates allow administrators to enforce expiration dates on SSH access, ensuring that keys cannot be used indefinitely. By implementing a Signing CA, organizations gain more control over SSH key management, enabling practices like short-lived access, automatic key expiration, and Just-in-Time (JIT) credentials without changing the underlying public keys on the servers.

---

## **Creating Expiring SSH Keys with a Signing CA**

### **Step 1: Create a Signing CA Key**

To introduce expiration dates for SSH keys, you first need to create an OpenSSH key to act as a Certificate Authority (CA). This CA will sign user keys and enforce expiration policies.

```bash
ssh-keygen -f ~/.ssh/ca_user -t rsa -b 4096 -C "SSH CA G-110940"
```

Next, store the CA’s public key on the remote server:

```bash
sudo mkdir /etc/ssh/trusted-user-ca/
nano /etc/ssh/trusted-user-ca/ca_key.pub
```

Paste the content of `ca_user.pub` into this file. Then, modify the SSH daemon configuration to recognize the CA key:

```bash
nano /etc/ssh/sshd_config
```

Add the following line:

```bash
TrustedUserCAKeys /etc/ssh/trusted-user-ca/ca_key.pub
```

Restart the SSH service to apply the changes:

```bash
sudo systemctl restart sshd
```

---

### **Step 2: Configure the Local Device**

With the CA key now trusted by the server, we can proceed to create user keys as normal:

```bash
ssh-keygen -f ~/.ssh/G-110940 -t rsa -b 4096 -C "SSH Key G-110940"
```

---

### **Step 3: Generate and Sign User SSH Keys**

We can now sign the user’s public key with the CA, specifying an expiration time:

```bash
ssh-keygen -s ~/.ssh/ca_user \
  -I ca-signed-access \
  -n richard \
  -V +1d \
  ~/.ssh/G-110940.pub
```

This command creates a certificate file (`G-110940-cert.pub`) valid for one day.

To use the signed key:

```bash
ssh -i ~/.ssh/G-110940 -o CertificateFile=~/.ssh/G-110940-cert.pub richard@34.27.255.12
```

Or configure this permanently in your SSH config file:

```bash
Host oracle-server
    HostName 34.27.255.12
    User richard
    IdentityFile ~/.ssh/G-110940
    CertificateFile ~/.ssh/G-110940-cert.pub
```

From there, SSH login will function as expected.

---

## **Why Use Expiring SSH Keys?**

The primary reason for using expiring SSH keys is security. Expiration dates reduce the window of opportunity for malicious actors if a key is compromised. Short-lived keys minimize potential damage, and new keys can be generated locally without changing the server configuration. Furthermore, if a device is lost or stolen, simply removing the certificate from the server instantly invalidates the key, preventing unauthorized access.

---

## **Just in Time (JIT) Logins for SSH**

If your organization or homelab employs Just-in-Time (JIT) access tools, this approach fits perfectly. A separate system can be configured to generate signed credentials that expire within 8 to 24 hours and securely transfer them to user devices. This ensures access is only granted when needed, reducing risk and increasing server security.

---

## **Conclusion**

Over the past year, I've explored numerous methods to protect SSH servers. Of everything I've tested, using expiring SSH certificates has been the simplest and most effective way to enhance SSH security. If you already run Linux servers that only accept SSH key authentication, and you can make those keys valid only when needed—often in under a minute—why wouldn’t you take advantage of this added security?

