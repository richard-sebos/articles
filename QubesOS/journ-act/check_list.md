
Here’s a flexible **Nyx Initiative Development Checklist**, organized into 4-hour work blocks you can jump between.  Each block is self-contained, so you can make progress even if you only have a short window.  Use this as your master “to-do hub.”

---

## ⚙️ Block 1 – Hardware & Base System

**Goal:** Get the Lenovo P52s ready for secure Qubes OS operation.
**Estimated:** 1–2 sessions (4–8 hrs total)

**Tasks**

* [ ] Install additional 16 GB RAM and run `memtest` overnight.
* [ ] Update BIOS / firmware to latest stable release.
* [ ] Disable unneeded devices (camera, mic, WWAN) in BIOS for testing.
* [ ] Set BIOS & boot passwords; disable external boot if possible.
* [ ] Create Qubes OS installation USB; verify SHA256.
* [ ] Install Qubes OS; confirm all devices detected (Wi-Fi, trackpad, SD reader).
* [ ] Apply all Qubes & template updates (`sudo qubes-dom0-update`).

---

## 🔐 Block 2 – Vault Foundation

**Goal:** Create and verify the hidden encrypted storage.
**Estimated:** ~4 hrs

**Tasks**

* [ ] Partition or create `/root/vault.img` (20–40 GB).
* [ ] Create detached LUKS header on SD card (`cryptsetup luksHeaderBackup`).
* [ ] Test mounting with header present → success; remove header → fail.
* [ ] Store SHA256 hash of header file in offline notes.
* [ ] Document mount/unmount commands in `vault_playbook.md`.
* [ ] Optional: create secondary “decoy” volume with dummy data.

---

## 🖥️ Block 3 – Decoy (“Veil Layer”) Prototype

**Goal:** Build the boss-mode UI that hides the true desktop.
**Estimated:** 4–6 hrs

**Tasks**

* [ ] Create `decoyuser` account with limited permissions.
* [ ] Implement `decoy_kiosk.py` or HTML kiosk version (fullscreen, fake spreadsheet).
* [ ] Write minimal `/usr/local/bin/unlock_vault.sh` helper with logging.
* [ ] Add secure sudoers entry (decoyuser → unlock script only).
* [ ] Test unlock sequence → mounts vault, closes decoy.
* [ ] Create recovery path (hotkey or console login if decoy fails).

---

## 🧩 Block 4 – VM Rebuild System

**Goal:** Automate re-creation of Qubes from a signed manifest.
**Estimated:** ~4 hrs

**Tasks**

* [ ] Draft `vm-manifest.yml` with 3–5 core VMs (sys-net, sys-firewall, vault, comm-tor).
* [ ] Write `rebuild.sh` (reads manifest, runs `qvm-create` commands).
* [ ] Add GPG signing & verification (`gpg --detach-sign`).
* [ ] Dry-run test in disposable environment.
* [ ] Log all rebuild steps to `~/vault_scripts/build.log`.

---

## 🧭 Block 5 – Backup & Update Automation

**Goal:** Secure data handling and GitHub offsite backup.
**Estimated:** ~4 hrs

**Tasks**

* [ ] Generate SSH key inside vault (`ssh-keygen -t ed25519`).
* [ ] Add deploy key to private GitHub repo.
* [ ] Write `backup-to-github.sh` (rsync → git → push).
* [ ] Write `update-templates.sh` (loop through templates).
* [ ] Test push/pull cycle; verify commit signatures.

---

## ☠️ Block 6 – Fade Protocol (Destruction)

**Goal:** Safe, controllable data-wipe and header destruction.
**Estimated:** ~4 hrs

**Tasks**

* [ ] Write `fade.sh` with `--dry-run` default; require `--confirm`.
* [ ] Integrate two-step check (passphrase + physical SD present).
* [ ] Test dry-run logs only.
* [ ] Document exact physical destruction steps for SD header.

---

## 🌒 Block 7 – Branding & Presentation

**Goal:** Make the experience cinematic & professional.
**Estimated:** ~4 hrs

**Tasks**

* [ ] Apply **Nyx Initiative** wallpaper / boot splash (use generated PNG).
* [ ] Customize GRUB text with ASCII logo.
* [ ] Set dark violet terminal palette and PS1 prompt.
* [ ] Add branded headers to all scripts.
* [ ] Write short intro paragraph for future blog (“Nyx Initiative – The Hidden System”).

---

## 📜 Block 8 – Testing & Audit

**Goal:** Validate each subsystem separately.
**Estimated:** multiple 4 hr sprints over several days

**Tasks**

* [ ] Run LUKS mount/unmount tests under varied conditions.
* [ ] Try incorrect passphrase → ensure no mount.
* [ ] Validate rebuild from zero using manifest.
* [ ] Verify backups restore cleanly on another Qubes host.
* [ ] Attempt decoy bypass (red-team simulation).
* [ ] Record outcomes and fixes in `nyx_test_report.md`.

---

## 🧠 Block 9 – Documentation & Playbooks

**Goal:** Capture processes so you can pick up any time.
**Estimated:** 4 hrs

**Tasks**

* [ ] Maintain `requirements.md` (done).
* [ ] Write `design.md` with flow diagrams and dependencies.
* [ ] Draft `operations_playbook.md` (mount, rebuild, fade).
* [ ] Create quick reference card (one page).
* [ ] Store printed copy in safe location.

---

### ✅ Optional Enhancements (fit any open block)

* TPM-based header sealing (`tpm2-tools`, `clevis`).
* Integrate `notify-send` pop-ups for success/failure.
* Add `nyx-watch` VM for daily integrity checks.
* Plan future article & screenshots for blog series.

---

Would you like me to turn this checklist into a **trackable Markdown table** with progress columns (e.g., `Status`, `Est hrs`, `Notes`) so you can mark off what you finish in Obsidian / VS Code?
