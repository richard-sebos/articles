---
title: Making CUPS Classes Work for You
subtitle: Simplifying Load Balancing and Failover Printing in Business Environments
date: 2025-10-19 10:00 +0000
categories: [Linux, Infrastructure]
tags: [CUPS, Printing, LinuxAdmin, Automation, LoadBalancing, Failover]
image:
  path: /assets/img/CUPS_Classes.png
  alt: CUPS Class configuration for printer load balancing and failover
---

# Making CUPS Classes Work for You

> *"There's never enough time to do it right, but there's always enough time to do it over."*
> — Jack Bergman

Time and again, I’ve been on projects where the original request missed the mark. Only after adapting to shifting needs did the true solution come into view. That’s why I never minded the extra effort—because in the end, a user would often say, “That’s what I really wanted all along.”

That’s why I appreciate projects that build in flexibility from the beginning. CUPS, the Common Unix Printing System, is one of those systems that offers just that. It includes features that not only handle basic print jobs but also scale up to meet more complex printing needs without re-architecting your environment. One of the most overlooked features is **CUPS Classes**, which can simplify everything from load balancing to failover in printer-heavy environments.

---

## Table of Contents

1. [What Are CUPS Classes?](#what-are-cups-classes)
2. [Round Robin Printing](#round-robin-printing)
     • [Step 1: Define Printers](#step-1-define-printers)
     • [Step 2: Create a Printer Class](#step-2-create-a-printer-class)
3. [Failover Printing](#failover-printing)
     • [Step 1: Create Two Printers](#step-1-create-two-printers)
     • [Step 2: Create a Failover Queue](#step-2-create-a-failover-queue)
     • [Step 3: Set Up the Class and Control Job Flow](#step-3-set-up-the-class-and-control-job-flow)
4. [Final Thoughts](#final-thoughts)
5. [🖨️ Command Summary](#️-command-summary)
     • [📌 Printer Setup](#-printer-setup)
     • [🧩 Creating a Printer Class](#-creating-a-printer-class)
     • [⛑️ Failover Setup](#-failover-setup)
     • [⚙️ Managing Printer States](#-managing-printer-states)

---

## What Are CUPS Classes?

If you’re running critical business processes that depend on printing, it’s not a matter of *if* a printer will fail—it’s *when*. Whether it’s a paper jam, a hardware issue, or simply not being able to keep up with growing demand, a single point of failure in your print pipeline is a risk you can’t ignore.

CUPS offers **printer classes** as a solution. A class in CUPS is essentially a virtual printer—a print queue that consists of multiple physical printers. When a print job is sent to the class, CUPS automatically assigns it to one of the available printers. This functionality provides a simple but powerful way to introduce load balancing and redundancy into your printing environment.

---

## Round Robin Printing

At my workplace, we use Zebra printers to print labels. Each label takes just **0.7 seconds** to print—an impressively short time. But when someone sends a batch of 150 labels and starts complaining that it's “too slow,” I do the math: even at full speed, that job will take over two minutes.

Now, if you could split that job across **five printers**, the same task could be completed in just **21 seconds** (assuming each print job is one label). That’s where CUPS Classes come in.

Here’s how to set up a printer class for round-robin printing:

### Step 1: Define Printers

```bash
sudo lpadmin -p vprinter1a -E -v ipp://192.168.35.131:631/printers/fileprint -P /etc/cups/ppd/vprinter1a.ppd
sudo lpadmin -p vprinter1b -E -v ipp://192.168.35.132:631/printers/fileprint -P /etc/cups/ppd/vprinter1b.ppd
sudo lpadmin -p vprinter1c -E -v ipp://192.168.35.133:631/printers/fileprint -P /etc/cups/ppd/vprinter1c.ppd
sudo lpadmin -p vprinter1d -E -v ipp://192.168.35.134:631/printers/fileprint -P /etc/cups/ppd/vprinter1d.ppd
sudo lpadmin -p vprinter1e -E -v ipp://192.168.35.135:631/printers/fileprint -P /etc/cups/ppd/vprinter1e.ppd
```

### Step 2: Create a Printer Class

```bash
sudo lpadmin -p vprinter1a -c rr_labels
sudo lpadmin -p vprinter1b -c rr_labels
sudo lpadmin -p vprinter1c -c rr_labels
sudo lpadmin -p vprinter1d -c rr_labels
sudo lpadmin -p vprinter1e -c rr_labels
```

Once the class `rr_labels` is created, applications can print directly to it, and CUPS will distribute the jobs among the printers. With minimal setup and the cost of extra printers, you can significantly improve print times and reduce user frustration.

---

## Failover Printing

Speed isn’t the only concern—reliability matters too. I've been called more than once to deal with a failed printer and a user standing beside it asking, "Can I just print to the one next to it?"

Using printer classes, you can also build **manual failover** systems. Let’s walk through that scenario.

### Step 1: Create Two Printers

```bash
# Primary Printer
sudo lpadmin -p vprinter1a -E -v ipp://192.168.35.131:631/printers/fileprint -P /etc/cups/ppd/vprinter1a.ppd

# Secondary Printer
sudo lpadmin -p vprinter1b -E -v ipp://192.168.35.132:631/printers/fileprint -P /etc/cups/ppd/vprinter1b.ppd
```

### Step 2: Create a Failover Queue

```bash
# Create a virtual printer that points to the secondary
sudo lpadmin -p vprinter1ab -E -v ipp://192.168.35.132:631/printers/fileprint -P /etc/cups/ppd/vprinter1b.ppd
```

### Step 3: Set Up the Class and Control Job Flow

Now create a class that includes both `vprinter1a` and `vprinter1ab`. Set `vprinter1ab` to **reject all jobs** so that CUPS sends everything to `vprinter1a` by default.

When `vprinter1a` goes down, simply:

1. Set `vprinter1a` to reject jobs.
2. Enable `vprinter1ab` to accept jobs.

This acts as a manual failover mechanism. Unfortunately, I haven’t found a reliable way to automate this switch with native CUPS tools—but even manual control is a step up from a hard stop in your workflow.

---

## Final Thoughts

CUPS Classes are a feature that many administrators overlook. I’ll admit, as a former developer, the term “class” initially made me think of object-oriented programming, and I dismissed it. But when I needed a solution for failover printing, I gave it a second look—and I’m glad I did.

This is one of those rare features that takes a standard, open-source tool and gives it enterprise-level flexibility. Whether you need speed, reliability, or both, CUPS Classes can help you build a more resilient printing infrastructure without having to redesign your environment.

---

## 🖨️ Command Summary

### 📌 Printer Setup

```bash
# Add a printer to CUPS
sudo lpadmin -p <printer_name> -E -v <device_uri> -P <ppd_file>
```

**Example:**

```bash
sudo lpadmin -p vprinter1a -E -v ipp://192.168.35.131:631/printers/fileprint -P /etc/cups/ppd/vprinter1a.ppd
```

* `-p`: Printer name
* `-E`: Enable the printer and accept jobs
* `-v`: URI of the printer (e.g., IPP, USB)
* `-P`: Path to the printer PPD file

---

### 🧩 Creating a Printer Class

```bash
# Add a printer to a class (creates the class if it doesn't exist)
sudo lpadmin -p <printer_name> -c <class_name>
```

**Example:**

```bash
sudo lpadmin -p vprinter1a -c rr_labels
```

* `-c`: Class name. If the class does not exist, it's created.

---

### ⛑️ Failover Setup

```bash
# Create a secondary "failover" printer pointing to another device
sudo lpadmin -p <failover_name> -E -v <failover_uri> -P <ppd_file>
```

**Example:**

```bash
sudo lpadmin -p vprinter1ab -E -v ipp://192.168.35.132:631/printers/fileprint -P /etc/cups/ppd/vprinter1b.ppd
```

---

### ⚙️ Managing Printer States

```bash
# Reject jobs for a printer
sudo reject <printer_name>

# Accept jobs for a printer
sudo accept <printer_name>

# Enable a printer
sudo cupsenable <printer_name>

# Disable a printer
sudo cupsdisable <printer_name>
```

**Example (Failover Switch):**

```bash
# Disable primary
sudo reject vprinter1a
sudo cupsdisable vprinter1a

# Enable backup
sudo accept vprinter1ab
sudo cupsenable vprinter1ab
```


