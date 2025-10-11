# Qubes “Movie Laptop” — Requirements Document

*Author: Richard Chamberlain*
*Project codename: Parallax Initiative*

---

## 1. Purpose

Provide a single-reference requirements document for building a highly compartmentalized, plausibly-deniable, “movie-style” secure laptop based on **Qubes OS**. This doc is the authoritative checklist to fall back on while designing, implementing, testing, and writing up the project.

---

## 2. Scope

* Hardware selection, firmware hardening, Qubes OS install and configuration.
* Hidden encrypted vault (detached LUKS header / key on removable token).
* Decoy UX (boss-mode) that hides the Qubes desktop and exposes it only after a secret unlock action.
* Helper scripts to: rebuild VMs (from manifest), backup to remote (GitHub) using keys in the vault, update templates/VMs, and destruct/wipe operations (with safe warnings).
* Operational controls: logging, tamper-evidence, testing and recovery playbook.
* Branding for fictional agency (Parallax Initiative).

**Out of scope:** hardware destruction, legal counsel, external hosting procurement, physical safe storage (these are noted in constraints and recommendations).

---

## 3. Stakeholders

* Primary: Richard Chamberlain (owner/operator).
* Secondary: Testers (red-team), blog readers (audience for write-up).
* No third-party commercial sponsors planned for initial implementation.

---

## 4. Goals & Non-Goals

### Goals

* Strong compartmentalization: network and secret isolation via Qubes VM topology.
* Plausible deniability: hidden vault with detached header and decoy data set.
* Recoverability: signed manifests and off-site encrypted backups.
* Usability: reliable “boss mode” decoy and robust unlock flow.
* Reproducibility: scripts that rebuild VM set from a signed manifest.

### Non-Goals

* Absolute “forensic-proof” erasure of SSDs. (SSD wear-leveling limits guarantee.)
* Automatic remote exfiltration or remote self-destruct. (Avoid for safety/legal reasons.)
* Production-grade firmware replacement (coreboot) unless hardware supports and user accepts risk.

---

## 5. Threat Model & Assumptions

### Adversary classes

* **Casual inspector** — non-technical (co-worker/searcher).
* **Skilled forensic investigator** — has physical access and forensic tools.
* **Remote attacker** — attempts remote compromise via networking.

### Key assumptions

* Operator physically controls removable header/key (USB or YubiKey).
* Operator will test all destructive scripts on disposable hardware first.
* Operator accepts that dom0 modifications are risky and will be minimized.

### Acceptable risks

* Forensic recovery from SSD may be possible if header still exists. Therefore: primary deniability relies on removable/externally stored header destruction.

---

## 6. Functional Requirements

Each item is numbered for traceability.

### FR-001 — Base install

* Install Qubes OS (latest stable release supported by chosen hardware).
* Create initial `user` account and lock dom0 to default secure settings.

### FR-002 — Hidden vault

* Create LUKS container (file-backed or partition) named `vault.img` with strong cipher (e.g., `aes-xts-plain64`, 512-bit).
* Support **detached header**: header can be backed up and removed to make vault indistinguishable from random data.
* Support keyfile stored on YubiKey or removable USB.

**Acceptance:** Cannot mount vault unless header + keyfile present; `cryptsetup luksDump` fails without header.

### FR-003 — Unlock flow

* Provide an unprivileged decoy process in dom0 (kiosk/fullscreen) that listens for secret passphrase or key sequence.
* On correct secret, decoy calls a limited helper script (`/usr/local/bin/unlock_vault.sh`) via `sudo` with strict sudoers entry.
* Helper script performs mount (`cryptsetup luksOpen --header ...`), mounts volume, copies or exposes scripts and optionally triggers VM rebuild.

**Acceptance:** Decoy should be able to trigger unlock exactly when secret is correct and log event; no alternative arbitrary command permitted via decoy.

### FR-004 — Rebuild manifest & scripts

* Maintain a signed `vm-manifest.yml` and `rebuild.sh` inside vault.
* `rebuild.sh` will create AppVMs and templates using Qubes CLI (`qvm-create`, `qvm-prefs`, `qvm-pool`).
* Scripts must verify `vm-manifest.yml`signature before executing.

**Acceptance:** Running `rebuild.sh` on a clean Qubes install should create specified VMs as per manifest (idempotent where possible).

### FR-005 — Backup & update

* Backup script `backup-to-github.sh` stored in vault; uses SSH key in vault to push encrypted archives to a private repository.
* Update script `update-templates.sh` to update templates and optionally rebuild AppVMs.

**Acceptance:** Successful signed push to private GitHub repo using vault-stored key.

### FR-006 — Secure deletion / ripcord

* Provide `ripcord.sh` that removes detached headers and overwrites keyfiles; must default to dry-run and require explicit `--confirm`.
* Provide strongly-worded warnings and require multi-factor confirmations (passphrase + YubiKey touch).

**Acceptance:** Script refuses to run without explicit flags and hardware token confirmation; performs only intended actions.

### FR-007 — Decoy UX & boss-mode

* Decoy should present convincing lightweight desktop or spreadsheet with fake data.
* Transition from decoy to Qubes UI must be smooth: kill decoy, restore panels/menus.

**Acceptance:** Cold boot into decoy by default; pressing the secret sequence switches to Qubes desktop.

### FR-008 — Logging & audit trail

* Maintain an append-only encrypted log in the vault of unlock attempts and rebuild events (timestamp + SHA of manifest + user) — `audit.log.gpg`.
* Keep local dom0 logs for troubleshooting but do not store secrets in plain text.

**Acceptance:** Log entries are created on unlock and signed or encrypted; verification possible.

---

## 7. Non-Functional Requirements

* **NF-001 (Security):** All sensitive keys must reside inside the vault or hardware token; no private keys stored in dom0 or untrusted AppVMs.
* **NF-002 (Usability):** Decoy must respond to unlock in <5s. Rebuild scripts should have `--dry-run` and `--verbose`.
* **NF-003 (Reliability):** Scripts must have error checks; failures must be logged and not leave half-done states.
* **NF-004 (Portability):** Manifest & scripts should be portable to another Qubes machine after verifying signatures and presence of header/key.
* **NF-005 (Auditability):** All scripts must be signed; helper scripts in dom0 must be read-only (mode 700) and only executable by sudoers entry.

---

## 8. Constraints & Limitations

* SSD forensic recovery limits wipe guarantees. Use detached header + physical destruction for plausible deniability.
* dom0 modifications are high-risk; minimal and auditable changes only.
* Qubes version changes may break scripts; all scripts must check Qubes version and abort on mismatch.

---

## 9. Architecture & Components

### Hardware

* Candidate models: ThinkPad T480/T580/P52s, Framework Laptop, ThinkPad X1 Carbon (verify Qubes hardware compatibility before purchase).
* Peripherals: YubiKey or Nitrokey, removable USB for header backup, external keyboard optional.

### Firmware

* UEFI secure boot recommended; BIOS password; disable external boot if appropriate. Consider TPM use.

### Software

* Host: Qubes OS (latest stable).
* Decoy: Python + GTK kiosk or a lightweight kiosk browser pointing at static HTML.
* Helper scripts: Bash (dom0 root) with strict permissions.
* Signing: GPG for manifests and scripts.
* Backup: Git and SSH, with key stored in vault.

### File layout (suggested)

```
/root/vault.img                  # LUKS file image (on disk)
/mnt/usb/vault.header            # detached LUKS header (on USB)
~/vault_scripts/                 # restored scripts after unlock
~/vault_scripts/vm-manifest.yml
~/vault_scripts/rebuild.sh
~/vault_scripts/backup-to-github.sh
/var/log/vault_unlock.log        # dom0 log (limited)
```

---

## 10. Operational procedures (playbook snippets)

### Normal boot

1. Insert header USB if you plan to unlock.
2. Boot machine → decoy UI loads.
3. To unlock: type secret phrase + Enter (or key combo). Decoy calls `sudo /usr/local/bin/unlock_vault.sh` → Vault mounts → scripts copied to home.

### Backup

1. Unlock vault.
2. Run `backup-to-github.sh` (or allow scheduled cron in vault).
3. Verify remote repo contains signed backup.

### Rebuild

1. Unlock vault.
2. Run `verify-manifest.sh` → verify signature.
3. Run `rebuild.sh --dry-run` then `rebuild.sh --confirm`.

### Ripcord / Emergency deletion

1. Insert YubiKey and type emergency two-step sequence.
2. Run `ripcord.sh --confirm --token-touch`. Script will shred header file(s) and remove keyfiles. **Physical destruction of USB header recommended afterwards.**

---

## 11. Testing & Acceptance Criteria

### Unit tests

* Validate LUKS header backup/restore functions on test VM.
* Verify decoy unlock calls helper only when passphrase correct.
* Test manifest signature verification routine.

### Integration tests

* Full rebuild on a clean Qubes install creates the expected VMs and network topology.
* Backup & restore cycle from GitHub (encrypted archive) works end-to-end.
* Ripcord dry-run refuses to proceed without `--confirm`. Confirmed run removes header and prevents vault mounting.

### Red-team tests

* Try to mount vault without header. (Should fail.)
* Inspect dom0 for evidence of hidden vault after header removed. (Should be minimal.)
* Attempt to escalate decoy privileges (should be sandboxed).

---

## 12. Deliverables

* `requirements.md` (this document).
* `design.md` (detailed architecture & flow diagrams).
* `decoy_kiosk.py` and packaged decoy assets (HTML/CSS).
* dom0 helper scripts: `unlock_vault.sh`, `ripcord.sh` (500-line max, well-commented).
* Vault contents: `vm-manifest.yml`, `rebuild.sh`, `backup-to-github.sh`, test keys.
* `playbook.md` — one-page quick recovery and emergency steps.
* Test suite: unit and integration scripts for verification.

---

## 13. Risks & Mitigations

* **Risk:** dom0 misconfiguration bricks system.
  **Mitigation:** perform changes on throwaway device first; maintain recovery USB with known-good dom0 backup.
* **Risk:** Accidental execution of destructive script.
  **Mitigation:** require multi-step confirmations and YubiKey; default to dry-run.
* **Risk:** Forensic recovery of deleted data.
  **Mitigation:** Detached header + physical destruction of header; accept limits of SSD technology.
* **Risk:** Sudoers misuse opens security hole.
  **Mitigation:** Only allow one script with fixed path & no args; document and sign sudoers file.

---

## 14. Compliance & Legal Notes

* Verify local laws regarding data destruction and plausible deniability. This project provides technical controls but not legal protection. Seek legal counsel when needed.

---

## 15. Appendix — Quick reference commands & file templates

(Only examples; always test on disposable hardware.)

**Create loopback LUKS & backup header**

```bash
fallocate -l 20G /root/vault.img
losetup /dev/loop0 /root/vault.img
cryptsetup luksFormat /dev/loop0
cryptsetup luksHeaderBackup /dev/loop0 --header-backup-file /mnt/usb/vault.header
```

**Open with external header**

```bash
losetup -f --show /root/vault.img  # prints /dev/loopX
cryptsetup luksOpen --header /mnt/usb/vault.header /dev/loopX vault
mount /dev/mapper/vault /mnt/vault
```

**Sign manifest**

```bash
gpg --detach-sign --armor vm-manifest.yml
gpg --verify vm-manifest.yml.asc vm-manifest.yml
```

**Sudoers line (example)**

```
decoyuser ALL=(root) NOPASSWD: /usr/local/bin/unlock_vault.sh
```

---

## 16. Next actions (recommended immediate tasks)

1. Choose hardware (one supported Qubes laptop).
2. Create throwaway test environment (VM or spare laptop).
3. Implement detached-header LUKS vault and test header backup/restore.
4. Implement decoy UI in dom0 (non-privileged) and a minimal helper script with logging.
5. Build and test manifest + rebuild script on test machine.
6. Iterate on UX and safety (dry-run modes, multi-factor confirmations).

