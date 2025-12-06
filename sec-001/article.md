# When RHEL 9 Meets a Legacy Windows Server: A Crypto Policy Story

## Intro: A Compatibility Challenge

Recently, I ran into one of those real-world IT problems that makes you stop and appreciate just how messy compatibility can be.

The setup was straightforward enough: I had a RHEL 9 server that needed to communicate with an older Windows server—nothing exotic. But this wasn’t just a lab test. It was a production-adjacent environment with real limitations, and no, upgrading the Windows box wasn’t an option (more on that in a minute).

As a recovering Linux snob, I’ll admit my first instinct was to think, “Of course it’s the Windows box causing trouble.” But I had to check myself—I've seen older RHEL versions do the same thing. Compatibility issues don’t discriminate.

---
## Table of Contents

* [Intro: A Compatibility Challenge](#intro-a-compatibility-challenge)
* [“Just Upgrade It” — A Costly Suggestion](#just-upgrade-it--a-costly-suggestion)
* [Enter: `update-crypto-policies`](#enter-update-crypto-policies)
* [The Middle Ground: Custom Crypto Policies](#the-middle-ground-custom-crypto-policies)
* [Real-World Security Isn’t Binary](#real-world-security-isnt-binary)

---

## Intro: A Compatibility Challenge

Recently, I ran into one of those real-world IT problems that makes you stop and appreciate just how messy compatibility can be.

The setup was straightforward enough: I had a RHEL 9 server that needed to communicate with an older Windows server—nothing exotic. But this wasn’t just a lab test. It was a production-adjacent environment with real limitations, and no, upgrading the Windows box wasn’t an option (more on that in a minute).

As a recovering Linux snob, I’ll admit my first instinct was to think, “Of course it’s the Windows box causing trouble.” But I had to check myself—I've seen older RHEL versions do the same thing. Compatibility issues don’t discriminate.

## “Just Upgrade It” — A Costly Suggestion

It’s easy to suggest upgrading the older server from a 50,000-foot view. But in reality, that can come with a cascade of hidden costs:

* Third-party software might not support the newer OS.
* Reinstalling or migrating apps takes time (and people).
* Unexpected downtime hurts users and IT alike.
* And let’s not forget: new versions sometimes bring *new* bugs and vulnerabilities.

I’ve seen “simple” upgrades spiral into projects costing anywhere from $1,000 to over $10,000 when you factor in lost time, planning, testing, and support. So—no—upgrading wasn’t the solution this time.

## Enter: `update-crypto-policies`

RHEL has a great tool called `update-crypto-policies` that helps manage system-wide cryptographic settings across applications like OpenSSL, OpenSSH, GnuTLS, Kerberos, and more. Instead of configuring crypto per service, you define one central policy that the system enforces.

RHEL ships with several predefined policies:

* **LEGACY**: Designed for backward compatibility (read: lower security).
* **DEFAULT**: A good balance of security and compatibility.
* **FIPS**: Strict compliance with U.S. government cryptography standards.
* **FUTURE**: Tighter restrictions for a more hardened future-ready system.

The goal for my RHEL server was to run in **FIPS** mode. But when we tried to talk to the older Windows server, the connection failed. After some digging, we found the culprit: cipher suite incompatibility. Dropping to `LEGACY` made it work—but we weren’t about to accept that as the final solution.

## The Middle Ground: Custom Crypto Policies

Here’s the cool part: RHEL’s crypto policy system supports **custom policies**. You can clone an existing one (like `FIPS.pol`) and modify it to suit your needs.

That’s exactly what we did. We copied the FIPS policy:

```bash
cp /usr/share/crypto-policies/policies/FIPS.pol /etc/crypto-policies/policies/CUSTOMER.pol
```

Then we added just the one cipher suite the old Windows server needed by updating:

* `ciphers`
* `mac`
* `hash`
* `key_exchange`

With that in place, we set our policy and rebooted:

```bash
sudo update-crypto-policies --set CUSTOMER
sudo reboot
```

Boom—now the system was running with nearly all FIPS-level restrictions, **except** for the single tweak that allowed it to talk to the legacy Windows box. We didn’t have to open the door to all the outdated protocols that `LEGACY` would have allowed.

## Real-World Security Isn’t Binary

In a perfect world, everything stays patched, every system is modern, and no app relies on a 15-year-old cipher suite. But we don’t live in that world.

Home labs are great because you control everything. In production, especially in SMBs or enterprises, change becomes significantly harder. Legacy systems can be tied to critical apps, and replacing or upgrading them isn’t always on the table—due to cost, risk, or vendor constraints.

Sometimes, the best you can do is **secure everything around the problem**—limit access, isolate it on the network, and use the strongest settings possible everywhere else.

And if you’re using RHEL? The crypto policy framework gives you a clean, centralized, and *auditable* way to do exactly that.

