# Securing Printers with CUPS: Why It Matters

## Table of Contents

1. [Introduction](#introduction)
2. [Why You Should Care](#why-you-should-care)
3. [Printer-Level Access Control](#printer-level-access-control)

   * [Controlling Where Print Jobs Come From](#controlling-where-print-jobs-come-from)
   * [Controlling Who Can Print](#controlling-who-can-print)
4. [Using Email Notifications in CUPS](#using-email-notifications-in-cups)
5. [Using Custom Policies](#using-custom-policies)
6. [Do You Really Need All This?](#do-you-really-need-all-this)
7. [Final Thoughts](#final-thoughts)
8. [CUPS Resources](#cups-resources)
9. [CUPS Command Cheat Sheet](#cups-command-cheat-sheet)

---

## Introduction

As a Linux administrator, you’ll often find yourself assigned to unexpected responsibilities—managing printers being a classic example. My journey with CUPS (Common UNIX Printing System) began with three servers handling over 50 printers. Over time, that infrastructure expanded to seven servers and over a hundred printers deployed across the country.

One question kept nagging me: should someone on the East Coast be able to see and print to a West Coast printer? This curiosity sparked a deeper dive into CUPS' access control capabilities and how it can be hardened to support secure, enterprise-scale print management.

---

## Why You Should Care

CUPS is deceptively simple. It provides a flexible, user-friendly printing environment for UNIX-like systems. That ease of use is great—until you realize it can lead to security vulnerabilities. By default, CUPS makes it fairly easy for users to view printer queues or job statuses. But without proper restrictions, users could pause a printer, cancel others’ print jobs, or even delete printers entirely.

Now consider what happens if an unauthorized or malicious actor gains access. They could disrupt business operations by deleting or altering configurations or accessing sensitive print jobs. Fortunately, CUPS includes **Role-Based Access Control (RBAC)** capabilities that can be configured on a per-printer basis—offering precise control over who can access what, and from where.

---

## Printer-Level Access Control

### Controlling Where Print Jobs Come From

In modern environments, printers often serve highly specific roles—printing shipping labels, receipts, checks, or legal documents. Ideally, these printers are isolated on their own subnets behind tight firewall rules. But CUPS lets you go a step further: you can limit exactly **which IP addresses** are allowed to send jobs to individual printers.

Here’s an example configuration in `cupsd.conf` that restricts access to a shipping label printer:

```conf
## Inside cupsd.conf
<Location /printers/SH_LABEL_IL_01>
  AuthType Basic
  Require ip 10.10.1.10         # Order processing system
  Require ip 127.0.0.1          # Localhost
</Location>
```

This ensures only authorized systems—like the order system or localhost—can send jobs, significantly reducing the printer’s exposure.

---

### Controlling Who Can Print

In a [previous article](https://richard-sebos.github.io/sebostechnology/posts/CUPS-RBAC/), I covered global access restrictions via the CUPS web interface. You can also restrict **printer-level** access based on users or groups. This is especially important for sensitive printers, such as those printing checks.

In `printers.conf`, you can assign access using directives like `Require user` or `Require group`. For example, to restrict check printing to the `ap_sup` group (Accounts Payable Supervisors):

```conf
<Printer AP_CHECKS>
  PrinterId 10
  Require group ap_sup
  ...
</Printer>
```

This not only restricts who can send print jobs, but also who can view them—helping prevent sensitive data leaks.

---

## Using Email Notifications in CUPS

For high-value printers—like check printers or those in secure locations—you may want better visibility into what’s being printed or when issues occur. CUPS supports a **subscription model** for sending email notifications on various printer or job events:

Common use cases include:

* `job-completed` – when a print job finishes
* `printer-stopped` – printer goes offline or is paused
* `printer-state-changed` – status change (pause/resume)
* `server-restarted` – when the CUPS daemon restarts

Example:

```bash
## Notify when job completes
lp -d PRINTER_NAME \
   -o notify-recipient-uri=mailto:you@example.com \
   -o notify-events=job-completed
```

Or to track printer outages:

```bash
## Notify when printer is stopped
lp -o notify-recipient-uri=mailto:you@example.com \
   -o notify-events=printer-stopped
```

> **Note:** CUPS needs access to an SMTP server to send email notifications.

---

## Using Custom Policies

In addition to user and IP-based controls, you can define **custom operation policies** in `cupsd.conf` to limit what actions are allowed per printer. These policies are assigned directly in the printer’s configuration.

For example, if you want to prevent check reprints by blocking access to `CUPS-Get-Document`:

```conf
## printers.conf
<Printer AP_CHECKS>
  PrinterId 10
  Require group ap_sup
  OpPolicy check-print
</Printer>
```

Then define the policy in `cupsd.conf`:

```conf
<Policy check-print>
  <Limit CUPS-Get-Document>
    AuthType Default
    Order deny,allow
    Deny from all
  </Limit>
</Policy>
```

This level of control gives you compliance-grade auditing and enforcement over who can do what with each printer.

---

## Do You Really Need All This?

Technically, no—CUPS will work fine out of the box without any of these customizations. But if you're running an enterprise print infrastructure, these configurations **don’t just secure the service—they secure your business processes**.

* You **prevent unauthorized use** of critical printers (like checks).
* You **limit exposure** by IP for function-specific printers (like shipping labels).
* You **proactively detect issues** via email alerts before users even call the help desk.

---

## Final Thoughts

A side note for the nerds: CUPS, like PuTTY, was released in 1999. Back then, single-core processors ran at 300–600 MHz. Today, I have a home server with dual sockets, 24 cores, and clocks around 2.5 GHz—and yet, CUPS remains that same humble, reliable print server quietly managing hundreds of thousands of jobs per month.

I've been in IT just a bit longer than CUPS has been around, and I honestly can’t recall a time when I didn’t have it as part of my toolbox. Whether you’re running three printers or three hundred, investing time in CUPS security and visibility features is worth every second.

---

## CUPS Resources

* 🔗 [CUPS Man Pages – Official Documentation](https://www.cups.org/doc/man-cupsd.conf.html)
* 📚 [General CUPS Documentation](https://www.cups.org/doc/)
* 🔐 [Previous Article: Global RBAC in CUPS](https://richard-sebos.github.io/sebostechnology/posts/CUPS-RBAC/)

---

## CUPS Command Cheat Sheet

| Command                                                 | Description                                                   |
| ------------------------------------------------------- | ------------------------------------------------------------- |
| `lp -d PRINTER_NAME -o notify-recipient-uri=mailto:...` | Print a file and receive email notification on job completion |
| `lp -o notify-events=printer-stopped`                   | Subscribe to printer offline events                           |
| `cupsctl`                                               | Configure CUPS settings from CLI                              |
| `lpstat -p`                                             | Show printer status                                           |
| `cancel -a`                                             | Cancel all print jobs                                         |
| `lpr -P printer file.txt`                               | Print a file to a specific printer                            |
| `lpadmin -p printer -u allow:user`                      | Restrict users from accessing a printer                       |
| `systemctl restart cups`                                | Restart CUPS service                                          |
| `lpoptions -p printer -l`                               | List available options for a printer                          |


