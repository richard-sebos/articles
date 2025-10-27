# *Securing Samba at the Global Level: Controlling the Server’s DNA*

When I first got into IT, I was all about planning. I’d spend hours researching, mapping everything out, and building the “perfect” install plan before touching anything. But, like most people find out sooner or later, things rarely go exactly as planned. There was always some hiccup that meant going back and tweaking things. These days, I take a more practical approach—working step by step, making sure things are stable before moving forward. It’s less about perfection upfront and more about building confidence as I go.

In the first part of this series, we got Samba up and running with a basic file share. That laid the groundwork. Now it’s time to start tightening things up. In this article, we’re going to focus on the heart of the Samba config—the `[global]` section. Think of this as setting the tone for your entire Samba deployment. We’ll walk through how to enforce encryption, restrict access, block old protocols, and keep logs in the right place—all to help lock down your server and build a secure baseline.

---

## 1. Introduction: The Root of Trust Lives in `[global]`

Samba’s config file (`smb.conf`) is split into two main blocks:

* **[global]** — sets server-wide defaults and policies
* **[share]** — configures individual shares, and can override `[global]` settings as needed

Why have both? The `[global]` section lets you define a consistent baseline that applies across all shares. This makes it easier to manage multiple Samba servers and keep your security posture uniform. Then, for those special cases, the `[share]` sections let you tighten or loosen access for individual shares.

---

## 2. Starting Baseline

Here’s the basic config we started with:

```ini
[global]
   workgroup = WORKGROUP
   security = user
   map to guest = Bad User
```

It works—but it's very permissive and leaves a lot of security holes. There’s no encryption, old protocols might still be allowed, and guest access is loosely handled. Let’s fix that.

---

## 3. SMB Protocol and Encryption

The SMB protocol is how clients (like Windows machines) communicate with your Samba server. Older Windows versions might require legacy SMB versions, but unless you have a hard requirement, those should be disabled.

Here’s how to lock Samba down to only allow modern, secure SMB versions:

```ini
   server min protocol = SMB3
   server max protocol = SMB3_11
```

| Version         | Status   | Recommended?          | Why / Why Not                                                      |
| --------------- | -------- | --------------------- | ------------------------------------------------------------------ |
| **SMB1**        | Obsolete | ❌ **Never**           | No encryption, vulnerable to **WannaCry**, lacks integrity checks  |
| **SMB2.0/2.1**  | Legacy   | 🔶 **Only if needed** | Better than SMB1, but still missing encryption                     |
| **SMB3.0/3.02** | Modern   | ✅ **Yes**             | Adds AES encryption + signing                                      |
| **SMB3.1.1**    | Current  | ✅ **Preferred**       | Adds pre-auth integrity, optional **TLS**, and stronger encryption |

Next, let’s require encryption and integrity protection:

```ini
   smb encrypt = required
   server signing = mandatory
   client signing = mandatory
```

| Setting                      | What It Does                          | Enforced?                     |
| ---------------------------- | ------------------------------------- | ----------------------------- |
| `smb encrypt = required`     | Requires AES encryption (SMB3+)       | ✅ Yes                         |
| `server signing = mandatory` | Ensures integrity of server messages  | ✅ Yes                         |
| `client signing = mandatory` | Ensures client traffic is also signed | ✅ Yes (when acting as client) |
| SMB over TLS                 | Full session encryption (TLS)         | ❌ No (requires `smbtls`)      |

*Note:* TLS encryption for SMB is possible but needs additional setup (certs + `smbtls` support). We’re skipping that here for now.

---

## 4. Locking Down Users

In our setup, we’re not using Active Directory or Kerberos. So we’ll stick with `security = user` and manage users locally.

Here’s how we tighten access:

```ini
   security = user
   passdb backend = tdbsam
   map to guest = never
   restrict anonymous = 2
```

* **`passdb backend = tdbsam`** separates Samba logins from system logins.
* Set Samba-only users with `/sbin/nologin` as their shell to prevent shell access.
* **`map to guest = never`** disables fallback to guest access.
* **`restrict anonymous = 2`** fully blocks anonymous access to shares and user info.

| Value | What It Does                 | Effect                                                      |
| ----- | ---------------------------- | ----------------------------------------------------------- |
| `0`   | No restrictions (default)    | Guests can list shares, users, etc.                         |
| `1`   | Block user/group enumeration | Guests can't list users but might still see shares          |
| `2`   | Fully restrict all anonymous | No share or user listing until authentication is successful |

---

## 5. Restrict by Network

You don’t want your Samba server exposed to random IPs on your network—or worse, the internet.

Here's how to only allow access from a known-good subnet:

```ini
   hosts allow = 192.168.35.0/24
   hosts deny  = ALL
```

This locks down access to just your local network (or whatever subnet you define). Yes, personal firewalls are more common now, but you shouldn’t rely on upstream devices for protection. Config changes, new interfaces, or routing quirks could accidentally open things up.

---

## 6. Logging: Get the Right Info to the Right Place

If you’re using a systemd-based Linux distro (which most are these days), Samba can integrate directly with the journal. That’s handy for centralized logging, especially if you're shipping logs to something like ELK, Graylog, or Loki.

```ini
   log level = 2 auth:3 vfs:3
   logging = systemd
```

* `log level = 2 auth:3 vfs:3` is a good level for testing—it gives useful auth and file system info.
* In production, you might drop this to `log level = 1 auth:2` for less noise.

---

## Wrapping Up: From Bare Minimum to Secure Baseline

Here’s a quick recap of what we did to lock down the `[global]` section:

* **Blocked old SMB versions** and required modern encryption
* **Forced signing** to protect data integrity
* **Disabled guest access** and anonymous lookups
* **Isolated users** using a separate password backend
* **Restricted IP access** to only a known subnet
* **Enabled structured logging** via systemd for better auditing

At this point, the Samba server is in a stable state. If no other changes were made, any shares you define would automatically inherit the security settings we’ve configured here.

That said, individual shares often need a bit more attention—sometimes locking things down even further, and other times relaxing rules based on specific needs. In the next part of this series, we’ll dive into share-level security and how to fine-tune access where it matters most.


