# 🧱 Securing the Network in QubesOS: Architecture, Routing, and Real-World Tests

> *“A deep dive into QubesOS network isolation and how to verify your VPN, TOR, and inter-VM firewalling actually works.”*

---

## 🔖 Table of Contents

1. [Introduction](#introduction)
2. [QubesOS Networking Basics](#qubesos-networking-basics)
3. [My Setup Overview](#my-setup-overview)
4. [Network Flow and Egress IP Mapping](#network-flow-and-egress-ip-mapping)
5. [Security Verification Tests](#security-verification-tests)
6. [Firewall Log Example](#firewall-log-example)
7. [Diagram: Visualizing the Network](#diagram-visualizing-the-network)
8. [Lessons Learned & Tips](#lessons-learned--tips)
9. [Conclusion](#conclusion)

---

## 📝 Introduction
AI has changed the speed of threat evolution — attacks can now learn, adapt, and pivot faster than most defensive systems can log a packet. The only sustainable defense isn’t more detection; it’s architecture.

QubesOS embodies that mindset. Instead of trusting software not to break, it assumes compromise is inevitable and contains the blast radius. Each virtual machine is a self-contained zone, isolated by design, with networking that forces every packet to earn its way out.

Over the past few weeks, I’ve been stress-testing how that model behaves in the wild — tracing VPN, TOR, and firewall flows, verifying isolation, and looking for cracks in the chain.

This isn’t a lab demo; it’s a blueprint for how we can design AI-ready containment systems — architectures that adapt faster than the threats they face.
---

## 🌐 QubesOS Networking Basics

Cover the key concepts:

* `sys-net`: hardware-facing NetVM
* `sys-firewall`: policy control, per-VM network rules
* `AppVMs`: user VMs like `work`, `untrusted`
* `sys-vpn`: custom VPN routing
* `sys-whonix`: TOR-based anonymity

Mention how Qubes uses **NetVM chains** for routing, and **IP address overlaps** are OK due to enforced isolation.

---

## 🧪 My Setup Overview

This is where you drop in your collected data.

* Include:

  * Which VMs you created
  * Which VM routes through which NetVM
  * IP and MAC info
  * Egress IPs observed via `curl ifconfig.me`

Use a bullet format or table for clarity.

> *Example: “I routed my `work` and `untrusted` VMs through `sys-firewall`, and routed `sys-firewall` through `sys-net`. I also configured `sys-vpn` and `sys-whonix` to route selected VMs through VPN and TOR respectively.”*

---

## 📡 Network Flow and Egress IP Mapping

Show how traffic flows from each VM:

| VM           | Internal IP      | NetVM Used   | External IP   |
| ------------ | ---------------- | ------------ | ------------- |
| sys-net      | 172.20.10.3/28   | (physical)   | 199.189.94.43 |
| sys-firewall | 10.138.22.13     | sys-net      | 199.189.94.43 |
| work         | 10.137.0.15/32   | sys-firewall | 199.189.94.43 |
| untrusted    | 10.137.0.16      | sys-firewall | 199.189.94.43 |
| sys-vpn      | 10.137.0.26/32   | sys-firewall | 45.84.107.74  |
| whonix       | 10.138.38.126/32 | sys-whonix   | 45.148.10.111 |

---

## 🔒 Security Verification Tests

Add hands-on tests you performed and their results:

### ✅ 1. Inter-VM Isolation Test

* Tried `ping` or `curl` from `work` → `untrusted`
* Checked `sys-firewall` logs
* ✅ Confirmed firewall drops traffic

### ✅ 2. VPN Leak Test

* Verified VPN IP via `curl ifconfig.me`
* Disabled OpenVPN tunnel to test failsafe
* ✅ Ensured no fallback to real IP

### ✅ 3. TOR Verification

* Used `whonix` to check external IP
* ✅ Verified TOR network in use

### ✅ 4. DNS Leak Check

* Ran DNS leak test from VPN and Whonix AppVMs
* ✅ DNS resolved only via VPN/TOR

You can expand each with terminal output, e.g.:

```bash
[user@work ~]$ curl ifconfig.me
199.189.94.43
```

---

## 📋 Firewall Log Example

Insert your actual `journalctl` output when you tested isolation:

```text
Oct 19 15:30:22 sys-firewall kernel: QUBES DROP: IN=vif12.0 OUT=vif14.0 MAC=... SRC=10.137.0.15 DST=10.137.0.16 ...
```

Explain what it shows: inter-VM traffic denied by default.

---

## 🗺️ Diagram: Visualizing the Network

Create or insert a diagram that shows:

* AppVMs
* ProxyVMs
* IP addresses
* Direction of traffic (arrows)
* VPN/TOR exit points

> *(You can ask me to generate one from your data if you’d like.)*

---

## 💡 Lessons Learned & Tips

Share what you found insightful, frustrating, or surprising. Some ideas:

* Using `/32` IPs for AppVMs makes them logically isolated
* Even on the same subnet, firewall rules prevent VM-to-VM traffic
* VPN failsafe is not built-in — needs explicit `iptables` rules
* `sys-net` is never to be trusted — it's the attack surface

---

## ✅ Conclusion

After weeks of tracing traffic, logging drops, and intentionally breaking things, one truth stands out: **Qubes doesn’t try to stop compromise — it limits the blast radius.** That containment mindset is the pattern cybersecurity needs as threats accelerate.

I’m still in the probing phase — mapping how these design principles might translate beyond Qubes into more adaptive, automated defenses. If you’ve experimented with similar setups or uncovered unexpected behaviors, I’d love to hear about them. Drop your observations, scripts, or lessons learned in the comments or DM me — I’m collecting real-world trade-offs and community insights for a follow-up piece.

---

### 🧭 Why this works

* Keeps your **“architect’s authority”** while emphasizing openness and exploration.
* Signals you’re leading a *conversation*, not pitching a product.
* Invites contributions that double as *market research* and *audience building*.
* Perfect tone for both **LinkedIn** (professional collaboration) and **Facebook groups** (peer discussion).

---

Would you like me to show you how to write a **LinkedIn post caption** that introduces this article using the same “probing phase” tone — something that’ll encourage thoughtful comments instead of quick likes?


## 🧾 QubesOS Networking & Security Command Cheat Sheet

> *Useful commands for inspecting and verifying network routing, VM isolation, VPN status, TOR routing, and firewall rules in QubesOS.*

---

### 🔍 **Check External IP (from any VM)**

```bash
curl ifconfig.me
```

> Shows the public IP that your VM presents to the internet.

---

### 🌐 **List All Qubes VMs with Networking Info**

```bash
qvm-ls --network
```

> Displays all VMs and the NetVM they're routed through.

---

### 🧭 **Inspect Network Interfaces (inside a VM)**

```bash
ip a
```

> Shows IP addresses and interfaces (e.g., `eth0`, `vifX.0`).

---

### 🗺️ **Trace the Route to an External Host**

```bash
traceroute google.com
```

> Reveals the network hops between your VM and the destination. Useful to visualize how packets flow through ProxyVMs.

---

### 🔐 **Check Firewall Rules in `sys-firewall`**

```bash
sudo iptables -L -v -n
```

> Lists the active iptables rules in the firewall ProxyVM.

---

### 📋 **Enable Logging of Dropped Packets (in `sys-firewall`)**

```bash
sudo iptables -I FORWARD -j LOG --log-prefix "QUBES DROP: " --log-level 4
```

> Inserts a log rule to see dropped traffic between VMs.

---

### 📜 **View Logged Drops in Real Time**

```bash
sudo journalctl -k -f
```

> Follows the kernel log for packet drops or firewall messages.

---

### 🧱 **Check Current NetVM for a Specific VM**

```bash
qvm-prefs <vm-name> netvm
```

> Example:

```bash
qvm-prefs work netvm
```

---

### 🔁 **Change the NetVM for a VM**

```bash
qvm-prefs <vm-name> netvm <new-netvm-name>
```

> Example:

```bash
qvm-prefs work netvm sys-vpn
```

---

### 🌐 **Test DNS Resolution Path**

```bash
dig @resolver1.opendns.com myip.opendns.com
```

> Confirms DNS is resolving through your VPN or TOR — useful for checking DNS leaks.

---

### 🧰 **Restart Firewall Service in a ProxyVM**

```bash
sudo systemctl restart qubes-firewall
```

> Re-applies default rules and clears custom changes.

---

### 🚦 **Verify OpenVPN Tunnel Interface (in `sys-vpn`)**

```bash
ip a | grep tun
```

> Look for `tun0` or similar to confirm the VPN tunnel is active.

---

### 🛑 **Create a VPN "Kill Switch" (block non-VPN traffic)**

```bash
sudo iptables -A OUTPUT ! -o tun0 -m conntrack --ctstate NEW -j DROP
```

> Blocks any outbound connection not going through the VPN interface.

---

### 🧱 **Dump All iptables Rules (for inspection or backup)**

```bash
sudo iptables-save
```

---

### 🔒 **Test TOR Routing in Whonix**

```bash
curl https://check.torproject.org
```

> Confirms you're using the TOR network properly.

---

## 📁 Optional: Save to File

Save this cheat sheet into a VM or doc:

```bash
cat > qubes-net-cheatsheet.txt <<EOF
[Paste content here]
EOF
```
