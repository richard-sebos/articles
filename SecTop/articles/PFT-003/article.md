# 🧩 **ProofTrail 3 — “Hash Chains for Humans: Proving History One Check at a Time”**

### 🎯 Goal

Create a timeline of verifiable integrity — every hash links to the one before it.

---

## Outline

### 1. Hook

> “Your system already remembers everything. Hash chains make sure you can too.”

### 2. Why Chains Work

* Linear evidence: each new check proves the previous baseline still exists unaltered.

### 3. Linux Walkthrough

```bash
LOGCHAIN=~/.prooftrail/logchain.txt
PREV=$(tail -1 "$LOGCHAIN" | awk '{print $1}')
sha256sum baseline.hashes | tee -a "$LOGCHAIN"
sha256sum "$LOGCHAIN"
```

* Automate with cron or systemd timer.

### 4. QubesOS Dom0 Walkthrough

```bash
for vm in $(qvm-ls --running --raw-list); do
    qvm-run -p $vm "sha256sum /etc/hostname" >> /home/user/.prooftrail/qubes_chain.txt
done
sha256sum /home/user/.prooftrail/qubes_chain.txt >> /home/user/.prooftrail/dom0_chain.txt
```

* Each VM contributes a fragment to the global ProofTrail.

### 5. Optional: Auto Commit to Git (Local Only)

```bash
git -C ~/.prooftrail add .
git -C ~/.prooftrail commit -m "Daily proof $(date +%F)"
```

### 6. Takeaway

> “Each line in your chain is a notarized moment of system truth.”

### 7. ProofTrail Teaser

> “Next, we’ll teach your logs to travel safely — encrypted and hardware-signed.”

---

