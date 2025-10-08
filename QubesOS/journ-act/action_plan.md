Absolutely — let’s lay this out like a **clear action plan** you could drop straight into your blog/article, or use as a personal checklist. This will show how a journalist or activist could set up Qubes OS step by step, going from install to hardened workflow.

---

# 📝 Action Plan: Securing Qubes OS for Journalists & Activists

---

## **Phase 1: Base System Hardening**

1. **Fresh Install with Encryption**

   * Install Qubes OS with **full-disk encryption**.
   * Choose strong passphrases for both disk and login.

2. **System Updates**
```text
This was opening system menu and get shell access to dom0
```
   * In `dom0`:

     ```bash
     sudo qubes-dom0-update
     ```
   * Update all templates (`fedora-xx`, `debian-xx`, `whonix-xx`).

3. **Dom0 Discipline**

   * Install nothing in `dom0` except Qubes-provided updates.
   * Only use it for qube administration and updates.

---

## **Phase 2: Role-Based Qube Layout**

Prefix every qube with `journalist-` to group them.

1. **Vault (no network)**

   * `journalist-vault` → store PGP keys, passwords, notes.
   * Set NetVM = `none`.

2. **Mail (restricted network)**

   * `journalist-mail` → for email.
   * NetVM = `journalist-net-vpn` (or Whonix for Tor).
   * Restrict firewall rules to mail servers only.

3. **Browser (network)**

   * `journalist-browser` → daily web browsing.
   * NetVM = `journalist-net-tor`.

4. **Research (isolated/disposable)**

   * `journalist-research-disp` → for opening untrusted docs/sites.
   * Configure mail/browser to launch attachments into disposables.

5. **Writing/Publishing (work)**

   * `journalist-writing` → for editing articles, preparing docs.
   * NetVM = `none` (offline) or `journalist-net-vpn` if needed for publishing.

6. **USB Handling**

   * `journalist-usb-lab` → for attaching and scanning USB sticks.
   * Keep sensitive qubes isolated from raw USB devices.

---

## **Phase 3: Networking Security**

1. **NetVM Variants**

   * Keep `sys-net` as physical NIC holder.
   * Create `journalist-net-vpn` and `journalist-net-tor`.
   * Chain them:

     * Example: `journalist-browser` → `journalist-net-tor` → `sys-firewall` → `sys-net`.

2. **Whonix Gateway**

   * Use Whonix qubes as Tor gateways instead of manual setup.
   * Route all anonymous browsing through `sys-whonix`.

3. **Per-Qube Firewalls**

   * Restrict each qube’s outbound domains/ports with:

     ```bash
     qvm-firewall journalist-mail
     ```

---

## **Phase 4: Qubes RPC & Key Management**

1. **Split-GPG**

   * Store keys in `journalist-vault`.
   * Run crypto operations from work qubes via RPC.

2. **Split-SSH**

   * Keep SSH private keys offline in `vault`.
   * Use `qvm-ssh` to connect through them.

3. **RPC Policy Review**

   * Edit `/etc/qubes-rpc/policy/` to restrict clipboard and file transfer.
   * Example: allow only `journalist-research` → `journalist-writing` file copy.

---

## **Phase 5: Hardware Security**

1. **USB Restrictions**

   * Keep `sys-usb` separate.
   * Only attach specific devices to `journalist-usb-lab`.

2. **Camera & Mic Isolation**

   * Route devices through a disposable or USB qube.
   * Only attach when needed.

3. **Networking Devices**

   * Disable unused NICs in BIOS.
   * Assign only trusted NICs to `sys-net`.

---

## **Phase 6: Operational Security**

1. **Disposable Burners**

   * Create `journalist-burner-*` qubes for one-time logins or sources.
   * Destroy after use.

2. **Metadata Stripping**

   * In research/disposables, run:

     ```bash
     mat2 filename.pdf
     ```
   * Ensures published docs/images don’t leak source info.

3. **Backups**

   * Regularly run:

     ```bash
     qvm-backup /mnt/encrypted-disk $(qvm-ls --raw-list | grep '^journalist-')
     ```
   * Store on encrypted external drives, kept separate from laptop.

4. **Emergency Shutdown**

   * Learn to run:

     ```bash
     qvm-shutdown --all
     ```
   * Practice “kill switch” habits if laptop seizure is likely.

---

## **Phase 7: Advanced Hardening**

1. **Multi-Factor Auth**

   * Store OTP secrets in vault.
   * Use YubiKey through a USB qube, not directly.

2. **Salt Automation**

   * Automate creation of qubes and firewall rules with Qubes Salt.
   * Reduces human error, enforces consistency.

3. **Kernel & Xen Settings**

   * Ensure IOMMU is enabled.
   * Apply microcode updates.
   * Disable unused PCI passthrough.

---

✅ At the end, your article can close with:

> *“This layered approach — from base hardening, to role-based qubes, to advanced operational practices — turns Qubes OS into more than just an operating system. For journalists and activists, it becomes a digital fortress where anonymity, security, and compartmentalization are daily tools of the trade.”*

---

Would you like me to **turn this action plan into a polished blog post draft** (friendly but professional tone, like your CUPS and Proxmox articles), or keep it in this checklist style so you can build from it?
