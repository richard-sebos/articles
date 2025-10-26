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
- A `/etc/aide.conf` will be created as part of the install and AIDE uses it to determine what to scan.
- It also create `/var/lib/aide/` where the compress database are kept.


This installs the configuration at `/etc/aide.conf`
and creates a working directory at `/var/lib/aide/`.

---

## 🧩 Initialize Your Baseline
- Before AIDE cand protect your system, a basedline needs to be created.
- To create a baseline run:
```bash
sudo aide --init
```

- It will store the baseline in  `/var/lib/aide/` as `aide.db.new.gz`.
- The `aide.db.new.gz` is generate when `aide --init` is run and needs to me moved to `aide.db.gz` to indicate it is an offical baseline.

```bash
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
```
- `aide.db.gz`  holds the cryptographic hashes for the directories specified in `aide.conf`

---

## 🔎 Verify Integrity

The baseline can be used to check the valitity of you system by running:

```bash
sudo aide --check | less
```

You’ll see a summary like:

```bash
sudo aide --check
[sudo] password for admin_richard: 
Start timestamp: 2025-10-25 17:36:40 -0600 (AIDE 0.16)
AIDE found NO differences between database and filesystem. Looks okay!!

Number of entries:	66624
```
- Your number of entries will be different from mine.
- My existing system matches what the baseline is for the files AIDE is keeping track of.


---

## 🧪 Step 4 — See It Catch a Change

Let’s make a harmless modification and rerun the check.

```bash
sudo touch /etc/testfingerprint
```

Expected output:

```
sudo aide --check 
Start timestamp: 2025-10-25 17:40:43 -0600 (AIDE 0.16)
AIDE found differences between database and filesystem!!

Summary:
  Total number of entries:	66625
  Added entries:		1
  Removed entries:		0
  Changed entries:		0

---------------------------------------------------
Added entries:
---------------------------------------------------

f++++++++++++++++: /etc/testfingerprint



```

That’s integrity in action — a single added file, immediately noticed.
-  Since it is a file we created, I update the baseline by:

```bash
sudo aide --update
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
```

---

## 🧠 Keep Your Baseline Safe

Copy `/var/lib/aide/aide.db.gz` somewhere read-only or encrypted.
That database is your **baseline witness** — if it’s altered, the entire trust chain collapses.

```bash
sudo cp /var/lib/aide/aide.db.gz /mnt/secure/aide.db.gz
```
---

## 🧭 Conclusion
- In the baseline I create was main based on '/etc` and ` `  directories were a majority of the system configuration files are stored
- It didn't include the`/usr` since as systems gets updated, it could cause multiple file updates.
- We did stop a melsoius user from get on the system but the critical files they would want to update to reconfigure the system has been basedline.
- Like any part of securing a Linux system, this just adds an layer detection with the hopes if you are attacked the layers will protect/dection will courge the hacker to find a easiler target

