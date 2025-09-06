# How to Secure Different User Types in Linux: A Guide for IT Teams
 
## Introduction

In my previous article, we discussed how to access a Linux application via SSH and the methods for securing SSH itself. Now, we turn our attention to securing the users of these systems. Most Linux environments I set up typically have two primary classes of users: **Linux Administrators** and **Application Administrators**. These roles often involve straightforward hardening strategies. However, what happens when additional user types are introduced into the system?

---
## Table of Contents

1. [Introduction](#introduction)
2. [Isn't Security the Same for All?](#isnt-security-the-same-for-all)
3. [Password and Account Expiration](#password-and-account-expiration)
4. [Mobile Computers and Handheld Terminals](#mobile-computers-and-handheld-terminals)
5. [Business Users](#business-users)
6. [Application Developers and Admins](#application-developers-and-admins)
7. [System Administrators](#system-administrators)
8. [Conclusion](#conclusion)

---


Beyond admins, organizations often have **business users** from departments such as finance, sales, administration, HR, and marketing, who are assigned individual devices. Additionally, there are **shared-use devices** like mobile computers, RF guns, barcode readers, and QR scanners, which may be used by multiple users. We also have **application developers** responsible for building and maintaining the software, and **system administrators**—whether they are Cloud Engineers, DevOps Engineers, or Site Reliability Engineers—who require deep access to the OS for system-level changes. Each of these user categories interacts with the operating system and application stack differently, and as such, each demands tailored security considerations.

---

## Isn't Security the Same for All?

It might seem outdated to discuss user-tiered security models, but these conversations are still very much relevant. IT teams aim to ensure that the organization's infrastructure investments remain secure, while business leaders strive to create a user-friendly environment for their staff. Both goals are valid, and finding a balance is essential.

A great example of this tension is found in mobile and handheld devices. Business needs often drive the use of simpler passwords due to small keyboards and limited character sets, whereas IT teams view these shared, often unattended devices as high-risk assets that demand stricter controls. Over the next few articles, we will continue to explore how to address these conflicting priorities and apply best practices.

---

## Password Expiration and Account Locks

Passwords are undergoing a shift in management philosophy. NIST SP 800-63B emphasizes **stronger passwords and breach monitoring** over traditional expiration models. Still, many organizations continue to use 60- to 90-day expiration policies. More critical, yet often overlooked, is **account locks**—a key area that can leave systems vulnerable to dormant accounts being exploited.

Should all users have the same password and account policies? Initially, my answer was no, but upon further analysis, the situation proved more nuanced.

---

## Mobile Computers and Handheld Terminals

These devices are often viewed as the most at-risk, yet I was surprised to discover that best practices recommend **no password expiration** or a rotation period of **180 to 365 days**, and that **accounts should never expire**. When considering the operational requirements, this makes sense. These are business-critical tools, and introducing frequent password changes can disrupt productivity.

To mitigate risks, additional controls are necessary on the Linux side:

* The application accessed via SSH should be a **stripped-down version** providing only essential functionality.
* Use `Match` and `ForceCommand` directives in SSH configurations to limit user actions.
* If these devices operate within an **isolated subnet**, SSH Match blocks should reflect that network segmentation.

During a recent meeting, I found myself thinking more like an application admin than a Linux admin. When you take a step back and assess these practices:

* Restrict user commands,
* Ensure users remain within the application sandbox,
* Monitor SSH logs regularly,

…it becomes clear why these leniencies exist—though it still feels counterintuitive from a strict security standpoint.

```bash
# Account never expires
sudo usermod -e '' username

# Disable password aging entirely
sudo chage -M 99999 username

# Require password change every 180 days
sudo chage -M 180 username
```

---

## Business Users

The security recommendations for business users aligned more closely with expectations. Passwords typically expire every **60–90 days**, if password expiration is used. Account expiration is often dictated by the user's employment status:

* **Seasonal or temporary workers**: Account set to expire on end date.
* **Contractors**: Account expiration aligned with contract end.
* **Permanent employees**: Account locking is preferred over expiration, especially after **45 days of inactivity**, or when users are terminated, on leave, or the account is suspected of compromise.

```bash
# Lock account with passwd
sudo passwd -l username

# Or lock account with usermod
sudo usermod -L username

# Unlock account with passwd
sudo passwd -u username

# Or unlock account with usermod
sudo usermod -U username
```

Multi-factor authentication (MFA) and SSH key authentication at the business user level are still rare. This isn’t due to technical limitations in Linux, but rather due to **HR policy constraints** and **logistical challenges** in distributing external authentication devices to non-technical users.

---

## Application Developers and Admins

Application developers and admin-level users typically operate across multiple environments and have **elevated access**, making them high-value targets for attackers. As such, their security requirements are stricter:
* **Contractors**: Account expiration aligned with contract end.
* Password expiration is usually set to **30–60 days**.
* Like business users, account **locking is preferred over expiration**, ideally after **30 to 45 days** of inactivity.

```bash
# Inactivity lock of 30 days
sudo chage -I 30 username
```

SSH key-based authentication and MFA are common and expected in this group, as these users generally have the technical skills to manage key generation and rotation.

---

## System Administrators

Security policies for system administrators are even more stringent. To my surprise, the best practices recommend password expiration within **15–30 days**, which is shorter than anything I’ve previously encountered. Due to their deep access into infrastructure, administrators often rely on:
* **Contractors**: Account expiration aligned with contract end.
* **Password vaults** for secure storage and rotation,
* **SSH authentication keys** or **short-lived SSH certificates**,
* **Mandatory MFA**, increasingly considered a baseline requirement.

Account locking is again preferred over expiration, within a **15–30 day** inactivity window.

```bash
# Find inactive accounts with no logins in the past 30 days
sudo lastlog -b 30
```

---

## Conclusion

While much of what I discovered aligned with expectations, there were definitely some surprises. Reflecting on the need for this article—yes, it is absolutely necessary. Across the many organizations I’ve worked with, and in conversations with peers, it's clear that standardized user security policies are often undocumented.

These practices should be seen as minimum baselines—the lower limits that organizations should strive to meet. From there, additional security policies can and should be layered on, depending on the sensitivity of the environment, risk posture, and business requirements. The key is to treat these recommendations not as a ceiling but as a foundation to build upon.

The first step in tightening user security is to document current practices and define **standards to aim for**. Often, the gap between current and desired security postures feels overwhelming, but implementing small, incremental improvements can gradually close that gap. In the next article, we will dive deeper into multi-tier password policy strategies.

