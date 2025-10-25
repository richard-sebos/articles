# 🧱 Every File Deserves a Fingerprint – AIDE on Oracle Linux 9

> *Before dashboards, before SIEMs, there was one simple question:  
> “Did my files change?”*  
> AIDE still answers that — silently and faithfully.

---

## 🔍 Why File Integrity Still Matters
- First heard of file intrusion back in the early 2000 when a co-work install an Open Source version of Tripwire.
- Tripwire scanned the Linux system he keep under his desk and he save the results to a flash drive mounted as read only.
- It seems like overkill back then but now days host-based intrusion detection tool are a key are of systne integrity
- Why no use logs to find this information?

## Log files as Intrusion Detection 
- Linux is good at logging critical active but it log all file changes
- In the past, I have created auditd rules to capture changes, but auditd sometimes created false positives
- There are great enterprise log aggration tools but what about users with a Linux laptop, workstation or small home lab
- System logs can lie. Attackers can clean traces. But file fingerprints don’t.  
- One tool you often see is for intrusion detection `AIDE` but what is it?

## AIDE
- **AIDE** or (Advanced Intrusion Detection Environment) takes a snapshit of the meta date for a number of directory in your Linux system.
- It creates a cryptographic hash for the files properties  create a way to verify the meta date was not changes.
- It created a conpress database file contain the baseline metadate that is read only and store where only root as access
- The compress database is used in the futre to compare files changes.
- These changes can be view to see which were validate and which could have been changed by an intruder.

## ⚙️  Install AIDE
- AIDE comes standard with most distros and on Fedore/RHEL base systems it can be installed with

```bash
sudo dnf update -y
sudo dnf install aide -y
````

This installs the configuration at `/etc/aide.conf`
and creates a working directory at `/var/lib/aide/`.

---

## 🧩 Step 2 — Initialize Your Baseline

Run AIDE once to build the first **database of checksums** —
your system’s initial fingerprint.

```bash
sudo aide --init
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
```

That file now holds cryptographic hashes (SHA256, by default)
for thousands of files across the OS.

---

## 🔎 Step 3 — Verify Integrity

Run a check to compare the current filesystem to your baseline.

```bash
sudo aide --check | less
```

You’ll see a summary like:

```
AIDE found differences between database and filesystem!!

Added entries:
    /etc/cron.d/aide
Changed entries:
    /var/log/messages
```

Those lines mean AIDE noticed a difference — in this case, a new cron job and an updated log file.

---

## 🧪 Step 4 — See It Catch a Change

Let’s make a harmless modification and rerun the check.

```bash
sudo touch /etc/testfingerprint
sudo aide --check | grep testfingerprint
```

Expected output:

```
Added entries:
    /etc/testfingerprint
```

That’s integrity in action — a single added file, immediately noticed.

Clean up afterward:

```bash
sudo rm /etc/testfingerprint
sudo aide --update
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
```

---

## 🧠 Step 5 — Keep Your Baseline Safe

Copy `/var/lib/aide/aide.db.gz` somewhere read-only or encrypted.
That database is your **baseline witness** — if it’s altered, the entire trust chain collapses.

```bash
sudo cp /var/lib/aide/aide.db.gz /mnt/secure/aide.db.gz
```

> 💡 **Pro Tip:** store a copy on a USB key or encrypted LUKS volume — the old-school version of a Vault Qube.

---

## 🧭 What You Just Built

You’ve created your first **verifiable fingerprint** of a running system —
a cryptographic baseline proving that your machine is exactly what you think it is.

This is the same logic the upcoming **ProofTrail** framework extends across isolated Qubes and cloud workloads.
Integrity starts with one checksum.

---
