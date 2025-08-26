## 🔧 Increasing SSH Capacity & System Limits (Friendly Explanation)

If you're running a server that needs to support **many concurrent SSH sessions** (like 400+ parallel SCP file transfers or many interactive users), the default Linux limits can get in the way — sometimes leading to errors like:

* “Too many open files”
* “Cannot fork: Resource temporarily unavailable”
* Slow or dropped SSH connections

To fix this, you'll need to raise some **resource limits** and make sure they apply correctly across users and services.

---

### ✅ 1. Increase User Limits in `/etc/security/limits.conf`

Add the following lines:

```bash
@yourgroup    hard    nofile      65536
@yourgroup    soft    nofile      65536
@yourgroup    hard    nproc       4096
@yourgroup    soft    nproc       4096
```

**What this does:**

* Increases the number of **open files** (`nofile`) per user — this includes files, network sockets, and more.
* Increases the number of **processes or threads** (`nproc`) a user can run at once.
* Applies to any user in the specified group (e.g., `appusers` or `devops`).

---

### ✅ 2. Ensure SSH Applies Those Limits

Edit `/etc/pam.d/sshd` and **add this line** if it’s not already there:

```bash
session    required     pam_limits.so
```

**Why this matters:**

* This tells SSH to apply the `limits.conf` settings during login.
* Without this, those per-user limits might be ignored when users connect via SSH.

---

### ✅ 3. Raise Kernel-Level System Limits

Add these lines to `/etc/sysctl.conf`:

```bash
# Increase max processes and file descriptors
fs.file-max = 2097152
kernel.pid_max = 4194303
kernel.threads-max = 2097152

# Networking buffers
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048

# Optional: expand ephemeral port range for outbound connections
net.ipv4.ip_local_port_range = 1024 65535
```

**Why this helps:**

* Raises system-wide file descriptor and process/thread limits.
* Expands TCP connection handling (important when many users or tools are connecting at once).
* Widens the range of **ephemeral ports**, which helps avoid port exhaustion when making lots of outbound connections (like `scp` or `curl`).

Apply changes immediately with:

```bash
sysctl -p
```

---

### ✅ 4. Set Limits Specifically for the SSH Service

Systemd services (like `sshd`) **don’t automatically inherit user-level limits**. You need to explicitly set limits for the service.

Create or edit the file:

```bash
/etc/systemd/system/sshd.service.d/limits.conf
```

Add:

```ini
[Service]
LimitNOFILE=65536
LimitNPROC=4096
```

**What this does:**

* Ensures the **SSH daemon itself** can handle many open files and processes.
* Complements the per-user limits set earlier.

> ⚠️ Without this, SSH might hit its own internal limits even if your users are allowed more.

---

### ✅ 5. Reload Systemd and Restart SSH

After editing the systemd config, run:

```bash
systemctl daemon-reexec
systemctl daemon-reload
systemctl restart sshd
```

This applies the new limits to the running `sshd` service.

---

## 🧪 You Can Verify It’s Working

After logging in via SSH, check the active limits:

```bash
ulimit -n    # Should show 65536 (open files)
ulimit -u    # Should show 4096 (processes)
```

---

## ✅ Summary

| Step                  | What It Fixes                            |
| --------------------- | ---------------------------------------- |
| `limits.conf`         | Allows users more open files & processes |
| `pam_limits.so`       | Makes those limits apply at SSH login    |
| `sysctl.conf`         | Raises kernel/system-wide limits         |
| systemd `limits.conf` | Ensures `sshd` can handle high load      |
| Restarting `sshd`     | Applies everything                       |

This setup is ideal for **secure, high-performance SSH environments**, especially if you're running automation, CI/CD tasks, large file transfers, or application access through SSH.

