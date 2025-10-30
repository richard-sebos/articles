
# 🔐 Trust but Verify – Signing and Securing Integrity Logs from dom0

> *File integrity means nothing if the logs can be tampered with.*
> In this follow-up, we move from checking integrity to **proving it cryptographically**.

---

## 📚 Table of Contents

1. [🧩 Why Signing Matters](#-why-signing-matters)
2. [🔐 GPG in the Audit VM](#-gpg-in-the-audit-vm)
3. [🛡️ Signing the Baseline](#️-signing-the-baseline)
4. [📜 Verifying Checks and Results](#-verifying-checks-and-results)
5. [⏱️ Timestamping and Log Rotation](#️-timestamping-and-log-rotation)
6. [⚙️ Optional: Building an Evidence Chain](#️-optional-building-an-evidence-chain)
7. [🧭 Conclusion – Integrity You Can Prove](#-conclusion--integrity-you-can-prove)

---

## 🧩 Why Signing Matters

In Part 1, we set up an integrity script in `dom0` that sends file hashes and metadata to a hardened audit VM. This keeps dom0 minimal and stateless. However, there's still one weakness:

> What proves that the **baseline or reports themselves** haven’t been tampered with?

Attackers may try to:

* Modify the baseline to hide malicious changes
* Alter integrity reports after the fact
* Replace the audit VM entirely

By **signing all baseline and check data**, you create a **verifiable chain of trust** that lets you confirm:

* The data was created by *you*
* It hasn’t changed since it was signed

---

## 🔐 GPG in the Audit VM

Your audit VM should have **GnuPG (GPG)** installed and configured with a **long-term private signing key**.

### Step 1: Generate a key

Inside the audit VM:

```bash
gpg --full-generate-key
```

Choose:

* Key type: RSA (default is fine)
* Key size: 4096 bits (recommended)
* Expiration: Choose based on your rotation policy
* Name/email: For traceability, e.g. `dom0-integrity@local`

List your keys:

```bash
gpg --list-keys
```

---

## 🛡️ Signing the Baseline

After receiving the baseline from `dom0` and saving it to a file like:

```bash
~/integrity/baseline-2025-10-30.txt
```

You can sign it:

```bash
gpg --output baseline-2025-10-30.txt.sig --detach-sign baseline-2025-10-30.txt
```

This creates a `.sig` file that proves the baseline is genuine. You can later verify it:

```bash
gpg --verify baseline-2025-10-30.txt.sig baseline-2025-10-30.txt
```

---

## 📜 Verifying Checks and Results

When `dom0` runs `run_integrity.sh check`, the resulting output can be piped and stored like:

```bash
~/integrity/check-2025-10-30_07-00.log
```

Now sign that report too:

```bash
gpg --detach-sign check-2025-10-30_07-00.log
```

This gives you:

```
~/integrity/
├── baseline-2025-10-30.txt
├── baseline-2025-10-30.txt.sig
├── check-2025-10-30_07-00.log
└── check-2025-10-30_07-00.log.sig
```

Every result is now **tamper-evident**.

---

## ⏱️ Timestamping and Log Rotation

To maintain a **clean audit trail**, use a timestamped filename convention:

```bash
DATE=$(date +"%Y-%m-%d_%H-%M")
OUTFILE="check-${DATE}.log"
```

You can also hash and sign results together for even more verification:

```bash
sha512sum "$OUTFILE" > "${OUTFILE}.sha512"
gpg --detach-sign "$OUTFILE"
```

### Optional: Make logs immutable after signing

```bash
chmod 400 "$OUTFILE.sig"
sudo chattr +i "$OUTFILE.sig"
```

---

## ⚙️ Optional: Building an Evidence Chain

For even more advanced setups, you can **chain the signatures** together by:

1. Creating a hash of the previous report
2. Including it in the **next report before signing**

This creates a **linked ledger** of integrity events:

```text
check-2025-10-30_07-00.log
→ includes hash of check-2025-10-29_07-00.log
→ signed
```

Even a deleted or missing report would break the chain — offering additional forensic visibility.

---

## 🧭 Conclusion – Integrity You Can Prove

With this second phase, your file integrity model becomes **cryptographically verifiable**, not just operationally sound.

✅ **dom0 remains untouched**
✅ **Audit VM holds the keys and proofs**
✅ **Every report is signed and timestamped**
✅ **You can verify authenticity and order**

This approach scales beyond Qubes — it’s a minimal, reproducible pattern that applies to hardened Linux setups where **trust must be explicitly proven**.

> In Part 3, we’ll explore how to **offload signed logs to a write-once medium**, such as a USB key or offline backup vault, completing the trust chain.

---

### 🔗 Related Resources

* 🔐 [Using GPG for Signatures](https://www.gnupg.org/documentation/)
* 🔍 Part 1: [Every File Deserves a Fingerprint](#)
* 🗃️ `man chattr`, `gpg --verify`, `sha512sum`

