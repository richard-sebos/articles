# 🧱 AIDE in Motion: Automating and Signing System Integrity Checks

> *If your system could testify, AIDE would be its expert witness.*
> In this article, we take the next step — not just monitoring integrity, but **proving** it.
> With automation, cryptographic signatures, and daily verification, your Linux system learns to **trust but verify itself**.

---

## 🧰 From Watching to Proving

## Introduction

I'll be the first to admit: encryption isn’t my strongest area.

Sure, I’ve used public and private keys for SSH authentication, and I’ve signed keys before — so I’m not starting from zero. But I’ve never gone deep into cryptographic principles or applied them to system integrity in a structured way.

That’s exactly why I wanted to write this article.

In a previous article, we installed and configured **AIDE (Advanced Intrusion Detection Environment)** — a silent guardian that creates a snapshot (or "fingerprint") of your Linux system, allowing it to detect when files unexpectedly change. It's a powerful tool for monitoring file integrity.

But this raises a crucial question:

> *If AIDE is verifying the integrity of the file system, who verifies the integrity of AIDE’s results?*

This is where **hashing** and **cryptographic signing** come into play. In this article, we'll explore how to use GPG (GNU Privacy Guard) to sign and verify AIDE databases and reports — building a trustworthy chain of integrity that can help detect tampering at every level.

Let’s dive in.

## GPG (GNU Privacy Guard)
Certainly — here's a cleaner, more technically precise version of your **GPG (GNU Privacy Guard)** section, rewritten for clarity and polish, while keeping it concise:

---

## GPG (GNU Privacy Guard)

**GPG** is a powerful encryption and signing tool used to ensure the confidentiality and integrity of files. In this context, we'll use it to **sign** the AIDE database, helping us verify that it hasn’t been tampered with.

### Key Concepts:

* GPG uses a **public/private key pair**:

  * The **private key** is used to sign or decrypt.
  * The **public key** is shared with others to verify signatures or encrypt data for you.

### Creating a Key Pair:

To create a key pair, use one of the following commands:

* `gpg --generate-key` – basic guided key generation
* `gpg --full-generate-key` – advanced options for key type, size, expiration, etc.

During the process, you'll be prompted to:

* Enter a **name and email address** (used to identify the key)
* Set a **passphrase** to protect your private key

After generating the key, a `.gnupg/` directory will be created in your home folder to store key data.

In the next steps, we’ll use GPG to sign a copy of the AIDE database — enabling us to later verify its authenticity and detect unauthorized modifications.
---

## 🗝️ Protecting and Signing the AIDE Baseline

When you run:

```bash
aide --init
```

AIDE creates a **baseline database** — a snapshot of the file system, based on the rules defined in `aide.conf`. This database acts as your system’s memory. If it’s modified, all trust in future integrity checks is lost.

In the previous article, we saved the baseline to:

```
/var/lib/aide/aide.db.gz
```

To protect this baseline, we’ll sign it using GPG and store the signed version securely. This allows us to verify its integrity before running any future checks.

---

### 🔒 Steps to Sign and Protect the Baseline

```bash
# 1. Create a secure location to store the signed baseline
sudo mkdir -p /root/.aide

# 2. Sign the baseline database with your private GPG key
sudo gpg --output /root/.aide/aide.db.gz.sig --detach-sign /var/lib/aide/aide.db.gz

# 3. Set strict permissions to prevent unauthorized access
sudo chmod 400 /root/.aide/aide.db.gz.sig

# 4. Optionally, use chattr to make the signature immutable
sudo chattr +i /root/.aide/aide.db.gz.sig
```

> 🔐 `--detach-sign` creates a separate signature file without modifying the original database.

---

### ✅ Verifying the Baseline Before Running Checks

Before running `aide --check`, verify the current baseline against the signed copy:

```bash
sudo gpg --verify /root/.aide/aide.db.gz.sig /var/lib/aide/aide.db.gz
```

Sample output:

```
gpg: Signature made Mon 27 Oct 2025 07:39:41 PM CST
gpg:                using RSA key 23CB30DFCF098B22F1ED3F1425F3E1E03154E84D
gpg: Good signature from "System Integrity (AIDE baseline signing key) <root@localhost>" [ultimate]
```

This confirms that the baseline file hasn’t been tampered with since it was signed.

---

## 🛡️ Protecting AIDE Check Results

Once you've signed and protected the baseline, the next critical step is to **protect the results of AIDE checks**. The `aide --check` command compares the current file system state to the baseline and outputs a report — this output must also be secured to ensure its trustworthiness.

---

### 📄 Generate and Save a Timestamped Log

Use the following to run a check and save the output to a timestamped log file:

```bash
LOG_DIR="/var/log/aide"
DATESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="${LOG_DIR}/aide-check-${DATESTAMP}.log"

# Create the log directory if it doesn't exist
sudo mkdir -p "$LOG_DIR"

# Run AIDE check and save output
sudo aide --check >"$LOG_FILE" 2>&1
```

This will create a log file like:

```
/var/log/aide/aide-check-2025-10-27_19-45-02.log
```

Just like the baseline, this file should be **hashed and signed** to detect any future tampering.

---

### 🔐 Hash and Sign the Log File

After generating the log, hash and sign it:

```bash
HASH_FILE="${LOG_FILE}.sha512"
SIG_FILE="${LOG_FILE}.sig"

# Generate SHA-512 hash
sha512sum "$LOG_FILE" >"$HASH_FILE"

# Sign the log file using your GPG key
gpg --output "$SIG_FILE" --detach-sign "$LOG_FILE"
```

This gives you:

* A `.sha512` file to verify the content checksum
* A `.sig` file to verify the log was not altered after signing

> 💡 Optional: Set restrictive permissions on the log, hash, and signature files, or move them to a protected directory like `/root/.aide-logs`.
Your log directory now contains a growing chain of tamper-evident reports:

```
/var/log/aide/
├── aide-check-2025-10-27_19-45-02.log
├── aide-check-2025-10-27_19-45-02.log.sha512
└── aide-check-2025-10-27_19-45-02.log.sig
```
---

### 🧪 Automating the Workflow

To simplify this process, you can use a custom script that:

1. Verifies the integrity of the last check result
2. Runs `aide --check` and logs the output
3. Generates a new baseline (optional)
4. Signs and hashes the new log file

You can find the full script [**here**](*insert-link-or-path*).

This approach ensures that **every stage** of AIDE — from the baseline to the reports — is protected against tampering or unauthorized modification.

---

## 🧭 Conclusion – Integrity You Can Prove
- The interesting thing about AIDE, it doesn't stop an attack.
- It finds eventance an attach has happened, which means an attack access to the system
- This adds an additional layer to the system to slow down attacker

> In the next phase, we’ll go one level deeper — linking each signature into a cryptographic ledger to create a verifiable, tamper-proof **evidence chain** across systems.

---

### 📚 Related Resources

* [AIDE-001: Every File Deserves a Fingerprint – AIDE on Oracle Linux 9](https://github.com/richard-sebos/articles/blob/main/Aide/AID-001/2025-11-xx-AIDE-Overview.md)
* `man aide.conf` and `man aide`
* `man systemd.timer`
* `gpg --help` for signing options

