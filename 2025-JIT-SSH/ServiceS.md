To start your `uvicorn` JIT SSH service on boot with a virtual environment and log output on a **MacBook Pro (macOS)**, the most appropriate method is to use a **LaunchDaemon**. Here’s a complete setup:

---

## ✅ Step-by-Step: Start FastAPI Service on Boot via LaunchDaemon

### 1. **Create a wrapper shell script**

Save this as:
`/usr/local/jit-ssh/start_jit_service.sh`

```bash
#!/bin/bash

# Activate virtual environment
source /usr/local/jit-ssh/venv/bin/activate

# Run uvicorn under correct user and redirect output
exec /usr/bin/sudo -u jituser /usr/local/jit-ssh/venv/bin/uvicorn jit_service:app \
    --host 127.0.0.1 --port 8088 >> /usr/local/jit-ssh/jit_service.log 2>&1
```

Make it executable:

```bash
chmod +x /usr/local/jit-ssh/start_jit_service.sh
```

---

### 2. **Create a LaunchDaemon plist file**

Save as:
`/Library/LaunchDaemons/com.jit.sshserver.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.jit.sshserver</string>

    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/jit-ssh/start_jit_service.sh</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/usr/local/jit-ssh/jit_service.stdout.log</string>

    <key>StandardErrorPath</key>
    <string>/usr/local/jit-ssh/jit_service.stderr.log</string>

    <key>UserName</key>
    <string>root</string>
</dict>
</plist>
```

---

### 3. **Set correct permissions**

LaunchDaemons require root ownership and tight permissions:

```bash
sudo chown root:wheel /Library/LaunchDaemons/com.jit.sshserver.plist
sudo chmod 644 /Library/LaunchDaemons/com.jit.sshserver.plist
```

---

### 4. **Load and start the service**

```bash
sudo launchctl load /Library/LaunchDaemons/com.jit.sshserver.plist
sudo launchctl start com.jit.sshserver
```

To verify it loads at boot:

```bash
sudo launchctl list | grep com.jit.sshserver
```

To stop or unload:

```bash
sudo launchctl stop com.jit.sshserver
sudo launchctl unload /Library/LaunchDaemons/com.jit.sshserver.plist
```

---

### 🔐 Security Note

If you use HTTPS (TLS), ensure the key/cert files have permissions allowing the `jituser` to read them.

---

Let me know if you'd prefer to use a `systemd`-like setup with `brew services` or `launchctl` under a user account instead.
