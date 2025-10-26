# 🧱 Securing the Network in QubesOS: Architecture, Routing, and Real-World Tests

> *“A deep dive into QubesOS network isolation and how to verify your VPN, TOR, and inter-VM firewalling actually works.”*

---

## 📝 Introduction
I began my IT career as a client/server programmer before transitioning into Linux system administration. More recently, I’ve been focusing on deepening my knowledge of networking — an area filled with concepts like subnetting, CIDR, ingress, egress, MTU, and VLANs. At first, these felt like abstract jargon. But as the landscape of cybersecurity evolves, the importance of understanding these fundamentals has become crystal clear.

AI has radically accelerated the pace of threat evolution. Modern attacks aren’t just faster — they’re adaptive, capable of learning and pivoting in real time. Defensive systems can barely log a packet before the threat has already morphed. In this new environment, more detection isn’t the answer. Architecture is.


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
## QubesOS embraces that philosophy
QubesOS embraces that philosophy. It doesn’t rely on the hope that software won’t break — it assumes compromise is inevitable and minimizes the impact. Each virtual machine operates as an isolated zone, with tightly controlled networking where every packet must earn its way out.

Over the past few weeks, I’ve been putting that model to the test: tracing VPN, TOR, and firewall flows, verifying isolation boundaries, and looking for weaknesses. This isn’t just another lab experiment — it’s a real-world exploration of how we can build AI-resilient containment systems. Architectures that adapt as fast as the threats they’re designed to survive.

## 🌐 QubesOS Networking Basics

QubesOS works by splitting your computer into separate compartments, each with its own virtual network connection. Only one part of the system is allowed to talk directly to the physical network, and it passes network access to the others, acting like a secure gatekeeper.

| **Component**      | **Description**                                                                                                                                                                                                             |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`sys-net`**      | - Connects directly to the physical network interface.<br>- Provides NAT and internal IPs to other VMs.<br>- Subnets the internal network for isolation.<br>- From the outside, all traffic appears to come from `sys-net`. |
| **`sys-firewall`** | - Filters traffic between AppVMs and `sys-net`.<br>- You can view its firewall rules with:<br>`bash<br>qvm-firewall sys-firewall<br>`<br>- Uses QubesOS `qvm` tools for rule management (more in future articles).          |
| **`sys-vpn`**      | - Clone of `sys-net` with OpenVPN configured.<br>- VPN starts automatically on boot.<br>- Any VM using `sys-vpn` routes traffic through the VPN.                                                                            |
| **`sys-whonix`**   | - Routes network traffic through the Tor network.<br>- Provides anonymity for VMs using it.<br>- Some websites may block or restrict Tor traffic.                                                                           |


---


## 📡 Network Flow and Egress IP Mapping

- I ran test to find out what the IP address were assigned to the differet network interface and proxies

| VM           | Internal IP      | NetVM Used   | External IP   |
| ------------ | ---------------- | ------------ | ------------- |
| sys-net      | 172.20.10.3/28   | (physical)   | 199.189.94.43 |
| sys-firewall | 10.138.22.13     | sys-net      | 199.189.94.43 |
| work         | 10.137.0.15/32   | sys-firewall | 199.189.94.43 |
| untrusted    | 10.137.0.16/32   | sys-firewall | 199.189.94.43 |
| sys-vpn      | 10.137.0.26/32   | sys-firewall | 45.84.107.74  |
| whonix       | 10.138.38.126/32 | sys-whonix   | 45.148.10.111 |
- Notice the IP address for the proxies have a /32 which  can't assign another host inside that subnet.
---

## 🔒 Security Verification Tests

Add hands-on tests you performed and their results:


| **Test**                  | **Steps Performed**                                                                                     | **Expected Outcome**                   | **Results / Notes**                                                    |
| ------------------------- | ------------------------------------------------------------------------------------------------------- | -------------------------------------- | ---------------------------------------------------------------------- |
| **1. Inter-VM Isolation** | - Trace route from `work` → `untrusted`<br>- Checked IP   s                         | Traffic should be blocked by firewall  | ✅ Traceroute gets to firewall no other IP found |
| **2. VPN Leak Test**      | - Checked external IP with `curl ifconfig.me`<br>- Disabled VPN to test failsafe                        | No traffic should leak real IP         | ✅ VPN enforced<br><br>Checked external IP with `curl ifconfig.me`<br>- Disabled VPN to test failsafe                    |
| **3. Tor Verification**   | - Launched browser in Whonix VM<br>- Checked IP at [check.torproject.org](https://check.torproject.org) | Traffic should route through Tor       | ✅ IP recognized as Tor exit node                                       |
| **4. DNS Leak Check**     | - Ran [dnsleaktest.com](https://dnsleaktest.com) from VPN and Whonix VMs                                | DNS should resolve only via VPN or Tor | ✅ No ISP or local DNS leaks detected                                   |

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


| **Category**                | **Command**                                                                 | **Description / Purpose**                                     | **Notes / Output**                              |
| --------------------------- | --------------------------------------------------------------------------- | ------------------------------------------------------------- | ----------------------------------------------- |
| 🔍 External IP Check        | `curl ifconfig.me`                                                          | Shows the public IP the VM presents to the internet           | Use in AppVM, VPN, or Whonix to verify IP       |
| 🌐 List VMs & NetVMs        | `qvm-ls --network`                                                          | Lists all VMs and their associated NetVMs                     | Useful to audit routing setup                   | 
| 🧭 Inside a VM: Interfaces  | `ip a`                                                                      | Displays IP addresses and interfaces (e.g., `eth0`, `vifX.0`) | Helps verify internal networking                | 
| 🗺️ Trace Route             | `traceroute google.com`                                                     | Shows the path packets take to reach a destination            | Good for identifying proxy hops                 |
| 🔐 View Firewall Rules      | `sudo iptables -L -v -n`                                                    | Lists active firewall rules in `sys-firewall`                 | Run in the ProxyVM                              |
| 📋 Log Dropped Packets      | `sudo iptables -I FORWARD -j LOG --log-prefix "QUBES DROP: " --log-level 4` | Adds logging rule to firewall                                 | Use with `journalctl` to monitor                |
| 📜 View Logged Drops        | `sudo journalctl -k -f`                                                     | Live log view of dropped packets & kernel messages            | Run in `sys-firewall`                           |
| 🧱 Show a VM’s NetVM        | `qvm-prefs <vm-name> netvm`                                                 | Displays which NetVM a VM uses                                | Example: `qvm-prefs work netvm`                 |
| 🔁 Change NetVM             | `qvm-prefs <vm-name> netvm <new-netvm>`                                     | Routes VM through a different NetVM                           | Example: `qvm-prefs work netvm sys-vpn`         |
| 🌐 DNS Leak Check           | `dig @resolver1.opendns.com myip.opendns.com`                               | Resolves IP via specified DNS server                          | Useful for VPN/TOR DNS validation               |
| 🧰 Restart Firewall Service | `sudo systemctl restart qubes-firewall`                                     | Reloads the firewall service in ProxyVM                       | Clears and reapplies rules                      |
| 🚦 Check VPN Tunnel         | `ip a\| grep tun`                                                           | Verifies if VPN tunnel (e.g., `tun0`) is active               | Run in `sys-vpn`                                |                 
| 🛑 VPN Kill Switch          | `sudo iptables -A OUTPUT ! -o tun0 -m conntrack --ctstate NEW -j DROP`      | Blocks traffic outside the VPN tunnel                         | Add to `sys-vpn` for safety                     |
| 🧱 Export Firewall Rules    | `sudo iptables-save`                                                        | Dumps all iptables rules to stdout                            | Useful for backup or audits                     |
| 🔒 Verify TOR Routing       | `curl https://check.torproject.org`                                         | Confirms you're using the TOR network                         | Run in Whonix AppVM                             |
| 📁 Save as File             | `cat > qubes-net-cheatsheet.txt <<EOF ... EOF`                              | Save this cheat sheet to a file in a VM                       | Replace with actual content                     |


