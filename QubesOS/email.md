# Using a Disposable Qube with Internet routed through Tor — Open each email in a Disposable Qube

**Short summary:** This article explains how to configure Qubes OS so that networked activity for a disposable qube is routed through Tor (Whonix), and how to arrange your mail workflow so each opened email or attachment is handled in its own disposable qube. It focuses on conceptual setup, concrete configuration tips, and important safety and threat-model considerations.

---

## TL;DR

* Use Whonix/Whonix‑DVM templates (sys‑whonix + whonix‑ws‑dvm) so disposables route through Tor.
* Make your mail client open messages / attachments using `qvm-open-in-dvm` so each message/attachment is handled in a fresh DispVM.
* Carefully set the NetVM of disposable templates to `sys-whonix` (or a Whonix‑based DVM template) and avoid accidentally giving persistent qubes direct net access.
* Understand the limits: Disposable VMs are not perfectly amnesic; Tor has fingerprinting and deanonymization risks, and mail servers may leak identity via headers. Always design a threat model.

---

## Who this is for

People who want to increase compartmentalization and reduce persistent traces when reading e‑mail on Qubes OS while routing network traffic through Tor. You should already be comfortable with Qubes concepts (dom0, TemplateVM, AppVM, DispVM, NetVM, tags) and with installing templates and editing simple configuration files inside AppVMs. If you’re unfamiliar, review the Qubes and Whonix documentation first.

---

## Important disclaimers and ethics

* **Legality & Ethics:** Tor and disposable VMs are privacy tools that have many legitimate uses (research, journalism, whistleblowing). They can also be used for illegal activity. I will not assist with illegal activity; use this guide only for lawful and ethical purposes.
* **Not full anonymity:** This setup improves compartmentalization and routes traffic through Tor, but it is not a magic bullet. User behaviour, mail provider metadata (headers, SMTP servers), browser plugins, fonts, timezones, and other signals can deanonymize you. Read the Whonix and Qubes threat‑model guidance.
* **Backups & recovery:** Disposable qubes intentionally discard state. Don’t rely on them for data you care about unless you explicitly export it before shutdown.

---

## High‑level architecture

1. **sys‑whonix** — a System (NetVM) which provides Tor connectivity for other qubes (the gateway). This is usually installed via the Qubes + Whonix integration.
2. **whonix‑ws‑dvm (Disposable template)** — a disposable template based on the Whonix workstation template that creates DVMs which use sys‑whonix for networking. Each new DVM is ephemeral and routes its traffic through Tor.
3. **Mail AppVM or Template** — your main mail AppVM (or a dedicated mail template) that you use to manage your mailbox(s). Configure it so that opening an email or attachment launches a Disposable VM.

The key: when the Disposable VM’s NetVM is sys‑whonix, any Internet connections it makes are proxied through Tor.

---

## Prerequisites

* A working Qubes OS installation (recommended recent stable release).
* Whonix / Qubes‑Whonix packages installed (sys‑whonix and whonix‑workstation templates). If you installed Qubes with the Whonix option or added Whonix templates later, you’ll have these.
* A mail client that works in Qubes (Thunderbird is a common choice). You can run it in an AppVM, and configure file associations to open attachments in dispVMs.
* Familiarity with Qube settings UI and the `qvm-open-in-vm` integration.

---

## Step 1 — Ensure sys‑whonix & Whonix disposable templates exist

1. Install or enable the Qubes‑Whonix packages according to the Qubes and Whonix guides. Typical Qubes installs provide a `sys‑whonix` NetVM and `whonix‑ws‑*-dvm` templates.
2. Confirm that you have a disposable Whonix workstation template (often named like `whonix‑ws‑<version>-dvm` or `whonix-ws-16-dvm`). This template is designed to create Disposables that already know how to use the Whonix gateway.

**Why:** Whonix provides the gateway+workstation architecture where the workstation directs traffic to the gateway which runs Tor. If the disposable template is based on Whonix‑workstation or configured to use `sys‑whonix` as its NetVM, then dispVMs created from that template will send traffic through Tor.

---

## Step 2 — Set the disposable template’s default NetVM to sys‑whonix

Open the Qubes Manager → right‑click the disposable template → Qube Settings → Advanced → Networking. Set Networking (NetVM) to `sys‑whonix` (or the Whonix gateway qube on your system).

**Important:** This makes every DispVM created from that template use Tor by default. Double‑check this before relying on it for anonymity.

---

## Step 3 — Configure your mail client to open messages/attachments in a DispVM

There are two common approaches:

### A. Use the desktop integration (`qvm-open-in-vm`) as default for relevant MIME types

1. In the mail AppVM, create a small `.desktop` entry that points to `qvm-open-in-vm` (or use the system menu editor) and mark it as the default application for file types you want to open in a DispVM (PDF, images, office docs, and — optionally — EML files).
2. For inline message viewing, configure your mail client to use an external viewer for message parts (many clients let you set an external viewer for attachments and sometimes for raw message files). Set that external viewer to `qvm-open-in-vm --dispvm '@dispvm' %f` (or the equivalent app entry) so each invocation launches a fresh dispVM.

This leverages the standard Qubes integration: `qvm-open-in-vm` will create a Disposable VM from the template and open the file inside it.

### B. Named disposable qubes + scripting (more advanced)

Create a tiny helper script or service that: copies a selected message to a temporary EML file and calls `qvm-open-in-vm` on that file. Optionally create a right‑click menu or custom toolbar button. This is useful if your mail client cannot directly open EMLs in an external viewer.

**Notes:**

* Many users configure attachments and external file opening so that **every attachment** opens in a dispVM automatically. That’s a good pattern for compartmentalization.
* If you want each *message* to be in its own dispVM, you will need to export or save each message to a file (EML or similar) and open that file with the disposable viewer command.

---

## Step 4 — Hardening & operational safety

* **Avoid mixing identities:** Don’t reuse persistent AppVMs that have identifying data for sensitive reading tasks. Treat the dispVM as the only place you view unknown or risky messages.
* **Disable clipboard/network bridges if needed:** Qubes has clipboard and file copy helpers (`qvm-copy`, `qvm-copy-to-vm`) — be cautious. Consider disabling clipboard sharing for disposable templates you use for anonymous work.
* **Time / timezone leakage:** Some apps reveal timezone or system time. If absolute anonymity is required, understand how timestamps in email headers or attachments could leak information.
* **Don’t use personal accounts:** If your threat model requires anonymity, avoid logging into personal accounts from dispVMs that you also use from non‑anonymous qubes.
* **Email metadata:** Opening an email in a dispVM affects only local handling. When the dispVM connects to an external SMTP/IMAP/HTTP server, that server will see connections from Tor exit nodes, but server‑side metadata (login, headers, IP logged at remote servers when messages were sent) may still link to you. Consider using anonymous mail providers or remailers where appropriate.

---

## Example workflows

### Workflow A — Attachment handling (safer, common)

1. Receive mail in MailApp (persistent AppVM).
2. Do not open attachments inline. Right‑click → Open With → `Open in Disposable VM` (your `qvm-open-in-vm` handler).
3. A disposable Whonix DispVM spawns (networked via `sys‑whonix`) and opens the attachment. When you close the window the DispVM is destroyed and state is removed.

### Workflow B — Full message review in per‑message DispVMs (more isolation)

1. In MailApp, select a message and export/save it as an `.eml` file to the mail AppVM’s temporary folder.
2. Right‑click the `.eml` → Open With → `Open in Disposable VM`.
3. The DispVM opens the message with your preferred viewer. Close to destroy.

This ensures each message is handled in its own ephemeral environment.

---

## Troubleshooting & pitfalls

* **DispVM won’t route through Tor:** Confirm the disposable template’s NetVM is set to `sys‑whonix` and that `sys‑whonix` itself has working Tor circuits. Check Whonix docs and Qubes Manager settings.
* **DispVM closes immediately:** Some users report that closing the first app window shuts the DispVM; keep the window open or use `qvm-console` if you need to interact with the VM longer.
* **Missing applications in dispVM:** If your disposable template lacks a viewer (e.g., `less`, `evince`, or Thunderbird), install the minimal viewer in the disposable template (or create a named disposable template that includes the viewer).

---

## Threat model checklist (quick)

* Are you protecting against local forensics? Disposable VMs help but are not perfect; disk caches or peripheral firmware can leak data.
* Are you protecting against network adversaries or the mail provider? Tor helps with network anonymity but does not remove identifying headers placed by mail servers or embedded metadata in attachments.
* Are you protecting against browser fingerprinting? Do not run browsers with plugins or fonts that could fingerprint you inside dispVMs.

---

## Further reading

* Qubes OS documentation on Disposables and AppVMs
* Whonix documentation on Qubes integration and Tor Browser usage
* Community threads and guides on using `qvm-open-in-vm` and setting mime handlers

---

## Closing notes

This guide provides a practical architecture and operational suggestions to route disposable qubes through Tor and to open each email or attachment in its own disposable qube. The exact commands and template names depend on your Qubes/Whonix versions. Always test carefully on non‑sensitive data first, and rethink your threat model continuously.

**If you want:** I can expand this into a step‑by‑step tutorial that includes example `.desktop` files and small scripts for common mail clients (e.g., Thunderbird) — or create a ready‑to‑copy configuration bundle for a specific Qubes + Whonix version. Let me know which version you run and whether you want named dispVMs or ephemeral ones.
