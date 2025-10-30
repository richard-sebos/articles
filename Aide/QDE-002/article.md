
# 🔐 Dom0 Integrity in Qubes OS: Replacing AIDE with Custom Signed Checks

> *Minimalist, verifiable, and Qubes-aligned — because even the base needs to be trusted.*

---

## 🧭 Table of Contents

1. [Why Replace AIDE in dom0?](#why-replace-aide-in-dom0)
2. [Design Goals](#design-goals)
3. [Step 1: Define What to Watch](#step-1-define-what-to-watch)
4. [Step 2: Baseline Hashing](#step-2-baseline-hashing)
5. [Step 3: Signing and Verifying](#step-3-signing-and-verifying)
6. [Step 4: Automating in dom0](#step-4-automating-in-dom0)
7. [Conclusion](#conclusion)

---

## Why Replace AIDE in dom0?

Qubes OS takes a security-first approach through isolation. However, even **dom0** — the management domain — can be a target. In minimal installs, adding packages like AIDE increases the attack surface and goes against Qubes' design philosophy.

Instead of relying on external tools, we can create a **custom lightweight file integrity system** using:

* Bash scripts
* `sha512sum` for hashing
* `gpg` for signing and verification

This achieves similar integrity guarantees as AIDE, with better control and **zero dependency bloat** in `dom0`.

---

## 🎯 Design Goals

* ✅ No additional software installed in dom0
* ✅ Operates via simple scripts and native tools
* ✅ Cryptographically signs integrity data
* ✅ Easily auditable and minimalistic
* ✅ Can be copied or templated for other Qubes components

---

## Step 1: Define What to Watch

Create a simple list of critical files and configs to monitor:

```bash
cat <<EOF > ~/.config/filewatch/files-to-check.txt
/etc/qubes/policy.conf
/boot/grub2/grub.cfg
/etc/fstab
/home/user/.bashrc
/etc/X11/xorg.conf.d/
/var/lib/qubes/qubes.xml
EOF
```

> You can expand this to include any sensitive file in dom0, but **do not** watch `/var/log`, `/tmp`, or fast-changing directories unless required.

---

## Step 2: Baseline Hashing

Create a baseline hash of the files:

```bash
#!/bin/bash
WATCHLIST="$HOME/.config/filewatch/files-to-check.txt"
BASELINE="$HOME/.config/filewatch/baseline.sha512"

mkdir -p "$(dirname "$BASELINE")"

sha512sum $(cat "$WATCHLIST") > "$BASELINE"
```

This file is your trusted snapshot. Now sign it.

---

## Step 3: Signing and Verifying

Generate a GPG key (if you haven’t already):

```bash
gpg --full-generate-key
```

Sign the baseline:

```bash
gpg --output "${BASELINE}.sig" --detach-sign "$BASELINE"
chmod 400 "${BASELINE}.sig"
chattr +i "${BASELINE}.sig"  # Make it immutable
```

### 🔍 To verify:

```bash
gpg --verify "${BASELINE}.sig" "$BASELINE"
```

If you see a **Good signature**, your baseline is intact.

To perform a daily check:

```bash
#!/bin/bash
BASELINE="$HOME/.config/filewatch/baseline.sha512"
TMPFILE="$(mktemp)"

sha512sum $(cat "$HOME/.config/filewatch/files-to-check.txt") > "$TMPFILE"
diff -u "$BASELINE" "$TMPFILE" || echo "⚠️ Files have changed!"
rm "$TMPFILE"
```

> Add GPG verification before diffing if extra integrity is needed.

---

## Step 4: Automating in dom0

**In dom0, avoid `cron`.** Use `systemd.timer` units instead:

### `~/.config/systemd/user/filewatch.service`

```ini
[Unit]
Description=Dom0 Integrity Check

[Service]
ExecStart=%h/.config/filewatch/run-check.sh
```

### `~/.config/systemd/user/filewatch.timer`

```ini
[Unit]
Description=Run Dom0 Integrity Check Daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

Enable it:

```bash
systemctl --user daemon-reexec
systemctl --user enable --now filewatch.timer
```

---

## ✅ Conclusion

You don’t need a full-blown AIDE installation in Qubes OS dom0 to maintain strong file integrity practices. With minimal tooling and automation, you can create a tamper-evident baseline and log system that:

* Works entirely with trusted native tools
* Respects Qubes' minimalism and security principles
* Keeps your base domain verifiably clean

This script-based replacement meets and exceeds the goals of AIDE in environments where *less is more* — and trust must be earned, not assumed.

---

### 📁 Optional Add-ons

* Export public GPG key to a USB for **offline verification**
* Create scripts to auto-rotate logs and signed snapshots
* Implement cross-domain alerts (e.g., notify a qube if integrity fails)

