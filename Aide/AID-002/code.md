# 📄 AIDE Daily Check Automation

This document provides an overview of the `aide-daily-check.sh` script, which automates daily integrity checks using **AIDE**, along with cryptographic verification using **GPG** and **SHA-512 hashing**. Combined with a `systemd` timer, this setup ensures that integrity checks are executed daily and are **tamper-evident**.

---

## 🔧 Files Overview

| File                                     | Purpose                                                                          |
| ---------------------------------------- | -------------------------------------------------------------------------------- |
| `/usr/local/bin/aide-daily-check.sh`    | Script to perform baseline validation, run `aide --check`, and secure log output |
| `/etc/systemd/system/aide-check.service` | Defines the one-shot systemd service                                             |
| `/etc/systemd/system/aide-check.timer`   | Triggers the service daily (via systemd timer)                                   |

---

## 🛠️ Setup Steps

### 1. Install the script

Create the AIDE check script:

```bash
sudo nano /usr/local/sbin/aide-daily-check.sh
```

Paste the script code (see [Script Details](#script-details)), then make it executable:

```bash
sudo chmod 700 /usr/local/sbin/aide-daily-check.sh
```

---

### 2. Create systemd service

**Path:** `/etc/systemd/system/aide-check.service`

```ini
[Unit]
Description=Run AIDE integrity check with baseline and log verification
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/aide-daily-check.sh
StandardOutput=journal
StandardError=journal
```

---

### 3. Create systemd timer

**Path:** `/etc/systemd/system/aide-check.timer`

```ini
[Unit]
Description=Run AIDE integrity check daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

---

### 4. Enable the timer

Reload systemd, enable the timer, and start it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now aide-check.timer
```

---

## 🧪 Script Workflow

The script `/usr/local/sbin/aide-daily-check.sh` performs the following actions:

1. **Baseline Verification**
   Confirms that the AIDE baseline (`/var/lib/aide/aide.db.gz`) matches its signature (`/root/.aide/aide.db.gz.sig`).

2. **Historical Log Validation**
   Iterates over previous logs in `/var/log/aide/`, verifying their SHA-512 hashes and GPG signatures. Any discrepancies are reported to `systemd-journal`.

3. **Run AIDE Check**
   Executes `aide --check` and logs the output to a timestamped file in `/var/log/aide/`.

4. **Log Signing and Hashing**
   Each log is:

   * Signed with your GPG private key
   * Hashed using SHA-512

   Output:

   ```
   /var/log/aide/
   ├── aide-check-YYYY-MM-DD_HH-MM-SS.log
   ├── aide-check-YYYY-MM-DD_HH-MM-SS.log.sig
   └── aide-check-YYYY-MM-DD_HH-MM-SS.log.sha512
   ```

---

## 🛡️ Logging and Alerts

All output is piped into `systemd-journald` using `systemd-cat` and tagged as `aide-check`.

You can view logs using:

```bash
journalctl -t aide-check
```

Example output:

```
Oct 28 06:15:01 hostname aide-check[...] ✅ Verified AIDE baseline signature OK.
Oct 28 06:15:02 hostname aide-check[...] ✅ AIDE integrity check passed.
Oct 28 06:15:03 hostname aide-check[...] 🧾 Signed and hashed integrity log: /var/log/aide/aide-check-2025-10-28_06-15-01.log
```

---

## 📝 Notes

* The script uses `sha512sum` and `gpg --detach-sign`. Ensure your GPG key is available to root.
* Modify the paths or GPG key configuration if running under a different user context.
* Consider forwarding journal logs to a centralized logging system for alerting and audit trails.

---

## 🧩 Related Articles

* [AIDE in Motion: Automating and Signing System Integrity Checks](https://github.com/richard-sebos/articles/blob/main/Aide/AID-002/2025-11-xx-AIDE-Signing.md)
* `man systemd.timer`
* `man aide`
* `gpg --help`


