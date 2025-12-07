---
title: "AIDE Ledger Chaining- Quick Reference"
subtitle: Essential Commands for AIDE Integrity Checks, GPG Signing, and Hash Chaining
series: "AIDE Security Series"
date: 2025-12-07 10:00 +0000
categories: [Linux, Security]
tags: [AIDE, FileIntegrity, GPG, Cryptography, LinuxAdmin, Security, Cheatsheet, QuickReference]
---

# AIDE Ledger - Quick Reference

**Essential Commands Only** | Updated: 2025-12-07

---

## 🚀 The 4 Core Operations

### 1️⃣ Run AIDE Check

```bash
# Run integrity check and save to log
aide --check > /var/lib/system_metrics/.l/aide-check-$(date +%Y%m%d).log
```

---

### 2️⃣ Hash the Log

```bash
# Calculate SHA-512 hash
sha512sum /path/to/logfile.log | awk '{print $1}'

# Save hash to file
sha512sum /path/to/logfile.log > /path/to/logfile.log.sha512

# Verify hash
sha512sum -c /path/to/logfile.log.sha512
```

---

### 3️⃣ Sign with GPG

```bash
# Create signature
gpg --detach-sign /path/to/logfile.log

# This creates: /path/to/logfile.log.sig

# Verify signature
gpg --verify /path/to/logfile.log.sig /path/to/logfile.log
```

---

### 4️⃣ Chain the Hashes

```bash
# For the FIRST entry (genesis block):
CHAIN_HASH=$(echo -n "$LOG_HASH" | sha512sum | awk '{print $1}')

# For ALL subsequent entries:
PREVIOUS=$(tail -1 /var/lib/system_metrics/.c | awk '{print $3}')
CHAIN_HASH=$(echo -n "${LOG_HASH}${PREVIOUS}" | sha512sum | awk '{print $1}')

# Add to ledger
echo "$LOG_HASH $LOG_FILE $CHAIN_HASH" >> /var/lib/system_metrics/.c
```

**Critical:** Use `echo -n` (no newline) when chaining!

---

## 📊 Quick Status Checks

```bash
# How many checks have run?
wc -l /var/lib/system_metrics/.c

# View last 5 entries
tail -5 /var/lib/system_metrics/.c

# When was last check?
tail -1 /var/lib/system_metrics/.c | awk '{print $2}'

# Total disk usage
du -sh /var/lib/system_metrics
```

---

## 🔧 Essential Setup Commands

```bash
# Create directory structure
mkdir -p /var/lib/system_metrics/{.l,.h,.s,.db}
touch /var/lib/system_metrics/.c

# Set permissions
chmod 700 /var/lib/system_metrics
chmod 700 /var/lib/system_metrics/{.l,.h,.s,.db}
chmod 600 /var/lib/system_metrics/.c

# Make ledger append-only (recommended)
chattr +a /var/lib/system_metrics/.c

# Remove append-only protection (for maintenance)
chattr -a /var/lib/system_metrics/.c
```

---

## 🧪 Quick Tests

```bash
# Test 1: Run a check manually
aide --check

# Test 2: Verify a hash
sha512sum -c /var/lib/system_metrics/.h/aide-check-*.sha512

# Test 3: Verify a signature
gpg --verify /var/lib/system_metrics/.s/aide-check-*.sig \
             /var/lib/system_metrics/.l/aide-check-*.log

# Test 4: View the ledger
cat /var/lib/system_metrics/.c
```

---

## ⚡ The Math Behind Chaining

```
Entry 1 (Genesis):
  log_hash_1 = SHA512(log_file_1)
  chain_hash_1 = SHA512(log_hash_1)

Entry 2:
  log_hash_2 = SHA512(log_file_2)
  chain_hash_2 = SHA512(log_hash_2 + chain_hash_1)

Entry 3:
  log_hash_3 = SHA512(log_file_3)
  chain_hash_3 = SHA512(log_hash_3 + chain_hash_2)

Entry N:
  log_hash_n = SHA512(log_file_n)
  chain_hash_n = SHA512(log_hash_n + chain_hash_(n-1))
```

**Result:** Each entry depends on ALL previous entries. Change anything → chain breaks.

---

## 📋 Ledger Format

```
<log_hash> <log_path> <chain_hash>
```

**Example:**
```
abc123... /var/lib/system_metrics/.l/aide-check-20251207.log def456...
```

**Fields:**
- `log_hash` = SHA512 of the log file
- `log_path` = Full path to the log file
- `chain_hash` = SHA512(log_hash + previous_chain_hash)

---

## 🎯 Common One-Liners

| Task | Command |
|------|---------|
| Run AIDE | `aide --check` |
| Hash file | `sha512sum file.log \| awk '{print $1}'` |
| Sign file | `gpg --detach-sign file.log` |
| Verify sig | `gpg --verify file.log.sig file.log` |
| Last chain hash | `tail -1 /var/lib/system_metrics/.c \| awk '{print $3}'` |
| Count entries | `wc -l /var/lib/system_metrics/.c` |
| View ledger | `cat /var/lib/system_metrics/.c` |

---

## ⚠️ Critical Rules

1. ✅ **ALWAYS use `echo -n`** when concatenating hashes
2. ✅ **NEVER edit** the ledger file manually
3. ✅ **ALWAYS verify** the chain before trusting it
4. ✅ **PROTECT with `chattr +a`** to make append-only
5. ✅ **TEST verification** after setup

---

## 🆘 Troubleshooting

```bash
# Check if AIDE is installed
which aide

# Check if GPG is installed
which gpg

# Verify you're root
whoami

# Check ledger file exists
ls -la /var/lib/system_metrics/.c

# Check ledger is writable
touch /var/lib/system_metrics/.c

# View file attributes
lsattr /var/lib/system_metrics/.c

# Check disk space
df -h /var
```

---

**Remember:**
- **AIDE** scans files
- **Hash** proves files unchanged
- **GPG** proves authenticity
- **Chain** proves history intact

**Simple formula:** `AIDE → Hash → Sign → Chain → Verify`
