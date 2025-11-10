# 🔐 SSH Access to Proxmox Without Exposing Your Lab
- virtual technolgy, once resisted just in data centers are now of part of home labs.
- You make us it as part of a small home business, a cyber learning tool or just as part of a home media server.
- There is one thing most hypervisiors have in common, the have some type of terminal software to do commandline  task from.
- A reader reachout asking for how my setup for SSH and Proxmox was done.
- As a homelaber or just as a computer user in general, you need to have the security that make sense for you and your use.
- Thou this written explain my Proxmox set, most things would be the same for other type of hypervisiors.



## Why have SSH to you Proxmox Server
- Most virtual host software has some type of gui/web user interface that covers most things user do but there are also almost aways a command line access.
- If there is a command line, there will be a group of IT, like me, who want to play in it.
- You are are the type that likes to tighten security,  automate setup, or just find out what else can be done, the commandline access is where that is at. 
- There are also another group of people that see it as a way of attacking a system and you need to protect the system from them
- Whose are the people you want to protect you system from

Let’s break it down into 3 focused parts:

---

## 🔧 Part 1: Lock Down `sshd` on Proxmox and the Jump Box

- The first in my security the Proxmox SSH connection is to create a jump server.  
- The jump server allows me one centeral point of SSH access to all server.
- It doesn't matter the Linux distro since its only goal is to security the `SSH` access

🛡️ Here's the approach it us:

* Disable passwords and root login
* Enforce strict key-based access
* Turn off agent forwarding, X11, and tunnels
* Limit login attempts and keep idle sessions short

```bash
# /etc/ssh/sshd_config 

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
I use this on my jump server, Proxmox VE server and most other server running SSH

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
- The first layer of security is to setup SSH auth keys to the jump server.
- in my case I used key type ed25519-sk
```bash
ssh-keygen -t ed25519-sk -f yub_id_ed25519_sk

## Need to allow password for short time to use below
ssh-copy-id -i yub_id_ed25519_sk hl_jump
```
- this  creates ed25519 keys that uses FIDO2 to generate the keys which
* 🔑 MFA enforced via **Yubikey touch**
* 🧩 SSH works only when your keys are present
- After changing my lab firewall to allow `SSH` from laptop to jump server, I know have access to my Linux VM and Proxmox server from the jump server.
- SSH ProxyJump is a great setting that allows you to setup a SSH server as a proxy get to other servre.
- I create a second key pair for the Proxmox server and have it setup so I can access the Proxmox server through the jump server
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
- The firewall doesn't allow laptop to access Proxmox through SSH
- You need the Yubico key, SSH auth key for both jump and Proxmox server to access the Proxmox through SSH

## QubesOS my final Security Level
- QubesOS is a Linux desktop run within a set of VM in a Xen Hypervisios, which is kind of backwards but fun to play with.
- Some of the VMs, which it calls Qubes, do not have web access but `dom0` VM can be used to move data between VMs
- I have a script that moves the SSH auth between the `work`  Qube I use to access the jump server and a vault Qube.
- `work` has access to network but not `dom0` or `vault`
- `dom0` and `vault` do not have external network access
- This limit the attack time of the jump server.


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

## Conclusion
- Is this overkill, it depends on what you security needs are.
- There will be groups of reads who will to secure the keys in the vault with encyption
- For other users it will be complete overkill
- That is why security laying works.
- You can use the layers that make sense for you.

---

## 🧰 Resources

* [QubesOS: Using Split SSH](https://www.qubes-os.org/doc/split-ssh/)
* [Proxmox SSH Access Guide](https://pve.proxmox.com/wiki/SSH)
* [OpenSSH `sshd_config` Manual](https://man.openbsd.org/sshd_config)
* [Yubikey for SSH](https://developers.yubico.com/SSH/)

---
