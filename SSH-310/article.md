# 🔐 SSH Access to Proxmox Without Exposing Your Lab
- virtual technolgy, once resisted just in data centers are now of part of home labs.
- If you are running L The different hypervisor do have a few thing 
I had a reader reachout asking for how my setup for SSH and Proxmox was done.
**A practical guide to jump hosts, hardened SSH configs, and optional QubesOS workflows**

If you’re securing a Proxmox server, you’re probably aiming for something simple:

> “I just want to SSH into my lab — without opening it up to the whole network.”

But like most careful homelabbers (myself included), you’ve likely hit a point where basic SSH access isn’t enough. You want the **Proxmox VE web UI shut down**, **SSH locked down**, and **no direct exposure** to your Proxmox subnet — not even from your own LAN.

That’s what this guide is for: to show you how to do SSH right — securely, repeatably, and in line with how real security architecture is built.

In this setup:

* Your Proxmox VE node lives on a **separate subnet**
* A **jump box** is your only way in
* You use **SSH keys + Yubikey MFA**
* You optionally run **QubesOS**, moving keys between vaults

Let’s break it down into 3 focused parts:

---

## 🔧 Part 1: Lock Down `sshd` on Proxmox and the Jump Box

Before you log in, **you define the rules**. SSH is your front door — and you want it reinforced, monitored, and hard to knock.

🛡️ Here's the approach:

* Disable passwords and root login
* Enforce strict key-based access
* Turn off agent forwarding, X11, and tunnels
* Limit login attempts and keep idle sessions short

```bash
# /etc/ssh/sshd_config (combined from include files)

# -- Authentication Controls --
PermitRootLogin no
AllowGroups ssh-users
PasswordAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
StrictModes yes
UsePAM yes

# -- Brute Force Protection --
MaxAuthTries 3
MaxStartups 3:30:10
LoginGraceTime 0

# -- Logging --
LogLevel VERBOSE
PrintLastLog yes
Banner /etc/ssh/sshd-banner

# -- Session Control --
ClientAliveInterval 300
ClientAliveCountMax 0
TCPKeepAlive no

# -- Forwarding & Tunneling --
AllowAgentForwarding no
AllowStreamLocalForwarding no
PermitTunnel no
GatewayPorts no
X11Forwarding no
```

This configuration:

✔️ Blocks all login methods except keys
✔️ Restricts access to the `ssh-users` group
✔️ Prevents lateral movement via SSH forwarding
✔️ Enforces short login grace and session timeouts

Want to go further? Shut down the Proxmox web UI until you explicitly need it:

```bash
sudo systemctl stop pveproxy
```

And restart it only when you’re ready:

```bash
sudo systemctl start pveproxy
```

This keeps your management interface fully offline — unless you're the one bringing it online.

---

## 🧭 Part 2: Use SSH ProxyJump to Traverse Securely

You’ve hardened your servers. Now it’s time to connect — without punching a hole in your firewall or logging into the jump box manually.

The goal here is **one command from your laptop** that gets you into the Proxmox server via the jump host.

🔁 **Your topology:**

```text
[QubesOS Laptop]
      │
  SSH + Yubikey
      │
   [hl_jump]
      │
 ProxyJump Only
      │
 [Proxmox VE]
```

Here’s how to do it:

### 🛠️ SSH Config (`~/.ssh/config`)

```ssh
Host hl_jump
    HostName <jump_box_ip>
    User richard
    IdentityFile ~/.ssh/hl_jump_key
    IdentitiesOnly yes

Host proxmox-pve
    HostName <proxmox_ip>
    User your_user
    IdentityFile ~/.ssh/proxmox_key
    ProxyJump hl_jump
    IdentitiesOnly yes
```

From here, connecting is simple:

```bash
ssh proxmox-pve
```

You’ll tap your Yubikey for the `hl_jump` connection, and SSH will route you straight through — **no extra login, no agent forwarding**, no attack surface left open.

This also ensures:

✔️ Your Proxmox node is never exposed to your LAN
✔️ Your jump box is never used interactively
✔️ Your SSH keys stay isolated

---

## 🧱 Part 3: (Optional) QubesOS: Vaulted Keys + Yubikey MFA

If you’re using QubesOS, you already think differently about security.

You compartmentalize. You isolate. You **don’t** leave SSH keys sitting on networked machines.

That’s why this setup includes:

* 🔐 Private keys stored in **Vault AppVMs**
* 🔑 MFA enforced via **Yubikey touch**
* 🧩 SSH config that works only when your keys are present

### 💼 Moving Keys from Vault to Networked AppVMs

Here’s how I manage SSH keys using a dom0 script:

```bash
#!/bin/bash
# dom0 script to move keys from vault to a target VM

TARGET_VM=$1
qvm-move-to-vm $TARGET_VM ~/.ssh/hl_jump_key
qvm-move-to-vm $TARGET_VM ~/.ssh/proxmox_key
```

You can trigger this from dom0 before initiating a connection. Once your session ends, remove and shred the keys:

```bash
shred ~/.ssh/hl_jump_key && rm ~/.ssh/hl_jump_key
shred ~/.ssh/proxmox_key && rm ~/.ssh/proxmox_key
```

🔐 **Bonus**: Since `hl_jump` requires Yubikey-backed keys, the connection can't proceed without your physical key and touch confirmation.

✔️ Keys stay offline by default
✔️ Vaulted VMs never touch the network
✔️ Physical MFA required to even begin connecting

---

## ✅ Final Checklist: What You’ve Just Built

You’ve moved from “just want to SSH into Proxmox” to a **layered, secure architecture** that’s built to last.

| 🧩 Component         | What You Did                                           |
| -------------------- | ------------------------------------------------------ |
| SSHD Configuration   | Disabled root, enforced key-only auth, blocked tunnels |
| ProxyJump SSH Config | Seamless, one-command access via a hardened jump box   |
| QubesOS Workflow     | Vaulted key storage + physical Yubikey MFA             |
| Proxmox UI Exposure  | Shut down by default, started only when needed         |

This setup is:

✔️ Private — nothing exposed to the LAN
✔️ Controlled — access flows only through what you’ve allowed
✔️ Auditable — no login surprises, no agent leaks
✔️ Secure — hardware keys, strong configs, and deliberate workflows

And best of all? You didn’t compromise usability to get there.

---

## 🧰 Resources

* [QubesOS: Using Split SSH](https://www.qubes-os.org/doc/split-ssh/)
* [Proxmox SSH Access Guide](https://pve.proxmox.com/wiki/SSH)
* [OpenSSH `sshd_config` Manual](https://man.openbsd.org/sshd_config)
* [Yubikey for SSH](https://developers.yubico.com/SSH/)

---
