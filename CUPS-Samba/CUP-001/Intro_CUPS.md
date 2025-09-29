---
title: Setting Up a CUPS Print Server on Linux
subtitle: Configure Centralized Printing with Network Access, IPP, and Web Interface
date: 2025-09-24 10:00 +0000
categories: [Linux, Infrastructure]
tags: [CUPS, Printing, IPP, LinuxServer, PrintServer]
image:
  path: /assets/img/cups_network_diagram.png
  alt: CUPS Print Server with Network Printer Access
---
## 1. **Introduction**

Printing is one of those technologies people rarely think about—until it stops working. Despite the rise of paperless workflows, printing remains deeply embedded in both personal and professional environments. Whether it's the receipt from your local coffee shop, the label on an Amazon package, or a contract printed in an office, some form of printing made it possible.

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Network Printers and Print Architecture](#2-network-printers-and-print-architecture)
3. [Installing and Configuring CUPS on RHEL/CentOS/Rocky](#3-installing-and-configuring-cups-on-rhelcentosrocky)
4. [Supported Printing Protocols](#4-supported-printing-protocols)
5. [Adding a Printer via Command Line](#5-adding-a-printer-via-command-line)
6. [Common CUPS Commands Cheat Sheet](#6-common-cups-commands-cheat-sheet)
7. [Where We Are Now](#7-where-we-are-now)
8. [Final Thoughts](#8-final-thoughts)

---

In enterprise settings, printing continues to drive key business functions—from invoicing and compliance documentation to shipping and logistics. It’s a technology that's everywhere, often invisible, yet still essential.

---

## 2. **Network Printers and Print Architecture**

Modern printing environments typically involve either locally connected devices or network-accessible printers. A **network printer** is any printer that can be accessed over a network, either via a built-in Ethernet or Wi-Fi interface or through printer sharing from another host.

These printers are accessed via IP addresses and are often managed centrally using a **print server**. A **print server** acts as a mediator between clients and printers, handling print job spooling, queuing, and scheduling. By queuing jobs before they hit the actual printer, the server effectively extends the printer’s limited internal buffer.

Inside each printer, the **print controller** is responsible for managing the flow of print jobs and converting them into formats the printer hardware can handle.

On Linux, the standard system for managing printers is **CUPS**—the Common UNIX Printing System. Most Linux distributions include it by default, and it provides the foundation for printer management, job queuing, driver support, and client access.

---

## 3. **Installing and Configuring CUPS on RHEL/CentOS/Rocky**

If CUPS is not already installed, you can install it using `dnf`:

```bash
sudo dnf install cups
```

Open the firewall port used by CUPS (IPP runs on TCP port 631):

```bash
sudo firewall-cmd --permanent --add-port=631/tcp
sudo firewall-cmd --reload
```

Before starting the service, some configuration changes are needed to enable and secure the web interface.

### Web Interface Configuration

Edit the CUPS main configuration file:

```bash
sudo vi /etc/cups/cupsd.conf
```

Set the port and IP address CUPS should listen on:

```conf
Port 631
Listen 192.168.35.125:631  # Replace with your server’s IP
```

Allow access to the web interface from specific networks:

```conf
<Location />
  Order allow,deny
  Allow localhost
  Allow 192.168.35.0/24  # VM Network
  Allow 192.168.20.0/24  # Home Network
</Location>
```

> 🔒 **Note:** Additional firewall rules or filtering at the network level are recommended for restricting access.

Restrict access to the admin section:

```conf
<Location /admin>
  AuthType Default
  Require user @SYSTEM
  Order allow,deny
  Allow 192.168.35.0/24
</Location>
```

The `@SYSTEM` group is defined in `/etc/cups/cups-files.conf`, and typically includes members of the `wheel` group (sudoers). Users in this group can manage printers via the web UI.

You can also configure logging here:

```conf
AccessLog syslog
```

This sends CUPS logs to the system journal (`journalctl`).

Once configuration is complete, start and enable the service:

```bash
sudo systemctl enable --now cups
```

---

## 4. **Supported Printing Protocols**

CUPS supports a wide range of protocols for interacting with different types of printers and clients:

| Protocol      | Description                                                                |
| ------------- | -------------------------------------------------------------------------- |
| **IPP**       | Internet Printing Protocol – native to CUPS, supports driverless printing. |
| **AirPrint**  | Apple's implementation of IPP with Bonjour discovery.                      |
| **LPD**       | Line Printer Daemon – legacy protocol, less secure.                        |
| **SMB**       | Samba-based printing for Windows clients.                                  |
| **AppSocket** | Also known as JetDirect (port 9100) – common for HP and legacy printers.   |

> ⚠️ **Security Tip:** Legacy protocols like LPD and SMB are more vulnerable. Where possible, prefer IPP or AirPrint for secure, driverless printing.

---

## 5. **Adding a Printer via Command Line**

You can add a printer using `lpadmin`:

```bash
sudo lpadmin -p HP_LaserJet -E -v ipp://192.168.35.126:631 -m everywhere
```

### Breakdown:

| Flag / Option    | Meaning                                                           |
| ---------------- | ----------------------------------------------------------------- |
| `lpadmin`        | CLI tool to configure CUPS printers.                              |
| `-p HP_LaserJet` | Sets the print queue name.                                        |
| `-E`             | Enables the printer immediately.                                  |
| `-v ipp://...`   | Device URI (IPP over port 631 to the printer’s IP).               |
| `-m everywhere`  | Uses IPP Everywhere (driverless) model for maximum compatibility. |

With **IPP Everywhere**, CUPS queries the printer for its supported capabilities (paper size, duplex, etc.), eliminating the need for vendor-specific drivers.

---

## 6. **Common CUPS Commands Cheat Sheet**

| Task                | Command                               |             |
| ------------------- | ------------------------------------- | ----------- |
| Check service       | `systemctl status cups`               |             |
| Start/Stop service  | \`sudo systemctl start                | stop cups\` |
| View printers       | `lpstat -p -d`                        |             |
| Add printer         | `lpadmin -p name -E -v URI -m driver` |             |
| Delete printer      | `lpadmin -x name`                     |             |
| Set default printer | `lpoptions -d printername`            |             |
| Print test file     | `lp /path/to/file`                    |             |
| View print queue    | `lpq`                                 |             |
| Cancel a job        | `cancel job_id`                       |             |

---

## 7. **Where We Are Now**

At this point, we have a functioning CUPS server that:

* Is accessible via a web interface from both my VM and home network.
* Allows users in the `wheel` group to manage printers through the admin web page.
* Can add, remove, and manage print queues, jobs, and permissions.
* Uses IPP Everywhere for driverless, modern printing.
* Still has some security considerations that need to be addressed.

While the default CUPS setup is suitable for small to medium business environments or departmental printing, additional configuration is recommended for larger deployments or environments with strict security requirements.

---

## 8. **Final Thoughts**

As someone running a home lab, I often uninstall CUPS if I’m not actively using a printer—it’s not needed on every machine. However, for small business or enterprise environments, **CUPS remains a solid and reliable print server solution**. It allows centralized print management, supports remote printing across sites, and reduces hardware dependency by serving as a print hub.

In future articles, we'll explore advanced CUPS configurations and security setting.

---
**Need Linux expertise?** I help businesses streamline servers, secure infrastructure, and automate workflows. Whether you're troubleshooting, optimizing, or building from scratch—I've got you covered.  
📬 Drop a comment or [email me](mailto:info@sebostechnology.com) to collaborate. For more tutorials, tools, and insights, visit [sebostechnology.com](https://sebostechnology.com).

☕ Did you find this article helpful?
Consider supporting more content like this by buying me a coffee:
Buy Me A Coffee
Your support helps me write more Linux tips, tutorials, and deep dives.