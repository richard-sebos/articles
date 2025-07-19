# 🔐 How to Secure SSH on Your Home Lab with Port Knocking (Step-by-Step)

## **Introduction: Why Port Knocking Matters**

**Every open SSH port is an open invitation.** Even in a home lab, exposed SSH services are routinely scanned by bots and malicious actors looking for a foothold. Leaving SSH visible on port **22** is practically begging for brute-force attacks.

For home lab users and junior sysadmins, **Port Knocking** provides a stealthy layer of security. It hides your SSH service completely until a secret sequence of network requests is sent — think of it as a "knock-knock" before entry is allowed.

In this guide, you'll learn exactly how to configure Port Knocking on Linux using `knockd` and `iptables` to keep your SSH server **hidden and secure.**

---

# 📋 **Table of Contents**

1. [What Is Port Knocking?](#what-is-port-knocking)
2. [Installing and Configuring knockd](#installing-and-configuring-knockd)
3. [Adjusting iptables for Port Knocking](#adjusting-iptables-for-port-knocking)
4. [Starting knockd with systemctl](#starting-knockd-with-systemctl)
5. [Testing Your Port Knocking Setup](#testing-your-port-knocking-setup)
6. [Next Steps: Dynamic Port Knocking](#next-steps-dynamic-port-knocking)

👉 **Continue to Part 2:** [Automating Port Knocking with Dynamic Port Rotation »](#)

---

## 1️⃣ **What Is Port Knocking?**

Normally, your SSH service listens openly on **port 22**, making it a common target. Port Knocking hides this service behind a firewall. Only after a specific **sequence of connection attempts** (knocks) to predefined ports does your server dynamically allow SSH access — temporarily and securely.

### 🔍 **How It Works:**

1. Client sends TCP connection attempts to hidden ports (the "knock sequence").
2. `knockd` detects the correct sequence.
3. Firewall dynamically opens SSH access for that client IP.
4. SSH connection becomes possible.
5. Optionally, another sequence can "lock" it again.

---

## 2️⃣ **Installing and Configuring knockd**

### 🔧 Step 1: Install knockd

On **Debian/Ubuntu**:

```bash
sudo apt update && sudo apt install knockd -y
```

On **CentOS/RHEL**:

```bash
sudo yum install knock -y
```

---

### 🔧 Step 2: Configure knockd

Edit `/etc/knockd.conf` to define your **custom knock sequences**:

```ini
[openSSH]
    sequence = 60842,31027,56118
    seq_timeout = 5
    command     = /sbin/iptables -I INPUT -s %IP% -p tcp --dport 22 -j ACCEPT
    tcpflags    = syn

[closeSSH]
    sequence    = 56118,31027,60842
    seq_timeout = 5
    command     = /sbin/iptables -D INPUT -s %IP% -p tcp --dport 22 -j ACCEPT
    tcpflags    = syn
```

💡 **Tip:** Customize the sequence to random high-numbered ports for extra obscurity.

---

### 🔧 Step 3: Enable knockd at Startup

Edit `/etc/default/knockd`:

```bash
START_KNOCKD=1
KNOCKD_OPTS="-i ens18"
```

➡️ Replace `ens18` with your network interface (`ip a` will show you).

---

## 3️⃣ **Adjusting iptables for Port Knocking**

Before you lock down SSH, ensure active connections won't get cut off mid-setup.

### ✅ Allow Established Connections

```bash
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

### ❌ Block SSH by Default

```bash
sudo iptables -A INPUT -p tcp --dport 22 -j REJECT
```

---

## 4️⃣ **Starting knockd with systemctl**

### 🔄 Reload systemd

```bash
sudo systemctl daemon-reload
```

### 🚀 Enable knockd at Boot

```bash
sudo systemctl enable knockd
```

### ▶️ Start knockd

```bash
sudo systemctl start knockd
```

### 🔍 Verify knockd Status

```bash
sudo systemctl status knockd
```

Look for `active (running)`.

---

## 5️⃣ **Testing Your Port Knocking Setup**

### 🔨 Open SSH Access

From your **client machine**:

```bash
knock -v your-server-ip 60842 31027 56118
```

Then attempt SSH:

```bash
ssh user@your-server-ip
```

### 🔒 Lock SSH Access Again

```bash
knock -v your-server-ip 56118 31027 60842
```

✅ Your SSH should now be inaccessible until you knock again.

---

## 6️⃣ **Next Steps: Dynamic Port Knocking**

While static port sequences work, **dynamic rotation increases security further**. By rotating knock sequences automatically, you reduce the risk of exposure if an attacker is watching.

👉 **Continue to Part 2:** [Automating Port Knocking with Dynamic Port Rotation »](https://dev.to/sebos/automate-port-knocking-with-dynamic-port-rotation-for-secure-ssh-access-pbh)
📂 **Config files and code available:** [GitHub Repository](https://github.com/richard-sebos/Ethical-Hacking-Robot/blob/main/SSH/knockd_readme.md)

---

# 🛡️ **Conclusion: Why This Matters for Your Home Lab**

You’ve now secured your SSH service behind an invisible firewall layer.
With Port Knocking in place:

* Bots and scanners can’t see your SSH port.
* Only you (or those with the knock sequence) can access it.
* Your home lab security is now smarter and stealthier.

🔐 **Security isn’t just about strong passwords — it’s about being invisible to attackers.** Port Knocking delivers exactly that.
