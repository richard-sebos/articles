
## Introduction

In the [previous article](https://richard-sebos.github.io/sebostechnology/posts/Users-Tiers/), we explored how to set up accounts for different types of users, including RF Guns, Application Users, Application Developers, and System Administrators, with a focus on account locks and expirations. Building on that foundation, this article examines how to implement password criteria tailored to each of these user types.
---

## Table of Contents

1. [Introduction](#introduction)
2. [Why Have Different Password Restrictions](#why-have-different-password-restrictions)
3. [Standard Password Setup](#standard-password-setup)
4. [Inline Restrictions](#inline-restrictions)
5. [Stack and Substack](#stack-and-substack)
6. [Is This Really Needed?](#is-this-really-needed)
7. [Conclusion](#conclusion)


---

## Why Have Different Password Restrictions

Few topics divide end-users and IT professionals as much as password restrictions. While users often view strict requirements as an inconvenience, IT professionals recognize them as a crucial security control. Not all users have the same level of access, and certain accounts hold privileged access that, if compromised, could provide attackers with critical entry points into the system.

Mandatory Access Control (MAC) systems such as SELinux can limit what users can access, but passwords still serve as the primary gateway for authentication. Best practices vary depending on infrastructure—organizations with strong logging and monitoring may place less emphasis on complex password rules, while others rely heavily on strict enforcement. For this article, we will start with a baseline requirement of at least 12 characters, using a mix of lowercase, uppercase, numerics, and special characters.

---

## Standard Password Setup

Most modern Linux systems use PAM (Pluggable Authentication Modules) to enforce password policies. The configuration file `/etc/security/pwquality.conf` allows administrators to set restrictions such as:

```bash
minlen = 12   # Minimum total password length
dcredit = -1  # Requires at least one digit
ucredit = -1  # Requires at least one uppercase letter
ocredit = -1  # Requires at least one special character
lcredit = -1  # Requires at least one lowercase letter
```

These settings apply restrictions globally across all users. Enforcement is handled by `pam_pwquality.so`, typically referenced in `/etc/pam.d/system-auth` and `/etc/pam.d/password-auth`:

```bash
password requisite pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
```

But what if different groups of users, such as RF Guns, need different password rules—for example, allowing numeric and alphabetic characters but excluding special characters?

---

## Inline Restrictions

PAM provides flexibility by allowing password rules to be defined directly within the `system-auth` or `password-auth` configuration files.

For example, RF Guns may require 12-character passwords containing lowercase, uppercase, and numeric characters, but no special characters:

```bash
password requisite pam_pwquality.so try_first_pass local_users_only retry=3 minlen=12 dcredit=-1 ucredit=-1 lcredit=-1
```

Meanwhile, Application Users might require stricter enforcement, such as 14-character passwords that also include special characters:

```bash
password requisite pam_pwquality.so try_first_pass local_users_only retry=3 minlen=14 dcredit=-1 ocredit=-1 ucredit=-1 lcredit=-1
```

This raises an important question: can both sets of restrictions coexist in the same environment?

---

## Stack and Substack

In PAM terminology, a single line is called a *policy*, and a collection of policies is referred to as a *stack*. These stacks can be separated into substacks, which are reusable configuration snippets.

For example, we can define a `password-rf_guns` substack with specific requirements:

```bash
# RF Guns password policy
password requisite pam_pwquality.so try_first_pass local_users_only retry=3 minlen=12 dcredit=-1 ucredit=-1 lcredit=-1 enforce_for_root
password required  pam_pwhistory.so remember=24 enforce_for_root use_authtok
password sufficient pam_unix.so sha512 shadow try_first_pass use_authtok
password required  pam_deny.so
```

Inside `system-auth` or `password-auth`, we can reference this substack so that members of the `rf_guns` group follow different criteria than others:

```bash
# Apply RF Guns substack if user is in rf_guns group
password [success=ok default=2] pam_succeed_if.so user ingroup rf_guns
password substack password-rf_guns
password [success=done default=ignore] pam_succeed_if.so user ingroup rf_guns

# Default policy for all other users
password requisite pam_pwquality.so retry=3 minlen=20 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1 difok=5 enforce_for_root
password required  pam_pwhistory.so remember=64 enforce_for_root use_authtok
password sufficient pam_unix.so sha512 shadow use_authtok
password required  pam_deny.so
```

The same approach can be extended to other groups, such as `app_users`, by creating a `password-app_users` substack and referencing it in a similar way. This ensures each group has password criteria aligned with its security needs.

---

## Is This Really Needed?

This configuration approach was inspired by a real-world discussion where RF Guns initially could not support special characters. Although the issue was resolved and special characters became usable, the exercise demonstrated how group-specific policies could be applied if needed.

There will always be cases where certain groups require either stricter or more relaxed password rules. Without separating users into groups, all accounts are forced to follow the same policy. If that policy is weakened to accommodate less capable accounts, it risks reducing the overall security posture of the system.

---

## Conclusion

Tailoring password restrictions to user groups allows organizations to balance usability and security without compromising either. PAM’s stack and substack mechanisms make it possible to apply different policies based on group membership, ensuring that security-critical accounts maintain strong protections while accommodating devices or users with practical limitations.

---
**Need Linux expertise?** I help businesses streamline servers, secure infrastructure, and automate workflows. Whether you're troubleshooting, optimizing, or building from scratch—I've got you covered.  
📬 Drop a comment or [email me](mailto:info@sebostechnology.com) to collaborate. For more tutorials, tools, and insights, visit [sebostechnology.com](https://sebostechnology.com).

☕ Did you find this article helpful?
Consider supporting more content like this by buying me a coffee:
Buy Me A Coffee
Your support helps me write more Linux tips, tutorials, and deep dives.