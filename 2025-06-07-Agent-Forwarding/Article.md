# 🚀 Remote Deployments with SSH Agent Forwarding and GitHub

Secure and scalable deployments are essential in modern DevOps workflows, especially when managing multiple remote servers. In this article, we explore how to leverage **SSH agent forwarding** in conjunction with **GitHub SSH key integration** to deploy code securely—**without storing private SSH keys on remote hosts**. This approach maintains security while enabling streamlined **remote deployments** through bastion hosts or jump servers.

---

## 📚 Table of Contents

1. [Introduction to SSH Key Authentication](#introduction-to-ssh-key-authentication)
2. [Why SSH Agent Forwarding?](#why-ssh-agent-forwarding)
3. [Configuring SSH Clients for Agent Forwarding](#configuring-ssh-clients-for-agent-forwarding)
4. [Setting Up SSH Agent Forwarding](#setting-up-ssh-agent-forwarding)
5. [Testing GitHub SSH Access from a Remote Server](#testing-github-ssh-access-from-a-remote-server)
6. [Security Concerns and Best Practices](#security-concerns-and-best-practices)
7. [Conclusion](#conclusion)

---

## 🔐 Introduction to SSH Key Authentication

SSH (Secure Shell) is a foundational tool for secure system administration and remote access. A key feature of SSH is its support for **key-based authentication**, which uses a **private key** stored on the user's machine and a corresponding **public key** on the server. This setup enhances security and allows for password-less logins.

But SSH is more than just a login tool—it’s also used by services like **GitHub** for secure `git pull` and `git push` operations. So, what happens when you want to **deploy GitHub code across multiple remote servers**? You could install the private key on each server—but that’s a security risk. This is where **SSH Agent Forwarding** comes in.

---

## 🔄 Why SSH Agent Forwarding?

**SSH Agent Forwarding** allows remote servers to use your local SSH keys **without copying or storing them** on those servers. When the remote server needs to authenticate with a third party (like GitHub), it securely routes the authentication request back to your local SSH agent, which signs the request and returns the result.

This ensures:

* Your **private keys never leave your local device**
* You can **authenticate from remote servers**, including through jump hosts
* It's fast and secure once configured

---

## ⚙️ Configuring SSH Clients for Agent Forwarding

Here's how to configure your local `~/.ssh/config` file to support **agent forwarding** and **jump servers**.

### GitHub Key

```bash
Host github
    HostName github.com
    User git
    IdentityFile ~/.ssh/includes.d/github/github
```

> No agent forwarding required here—this is just local GitHub access.

### Jump Server (Bastion Host)

```bash
Host rhel_jump
    HostName 34.58.111.124
    User richard
    Port 22
    ForwardAgent yes
    IdentityFile ~/.ssh/includes.d/rhel_jump/rhel_jump
```

> Enables agent forwarding through the jump server.

### Remote Target Server (e.g., ROS2)

```bash
Host sros
    HostName 34.123.21.106
    User richard
    Port 22
    ProxyJump rhel_jump
    ForwardAgent yes
    IdentityFile ~/.ssh/includes.d/rhel_jump/rhel_jump
```

> This setup uses `ProxyJump` and `ForwardAgent` to securely access the ROS2 server **without direct SSH key storage**.

---

## 🛠️ Setting Up SSH Agent Forwarding

### On the Remote Server

Ensure the following directive is present in the `/etc/ssh/sshd_config` file:

```bash
AllowAgentForwarding yes
```

Then restart the SSH service:

```bash
sudo systemctl restart sshd
```

### On Your Local Machine

Use `ssh-add` to load your SSH keys into the agent:

```bash
ssh-add <path_to_key>
```

Or use this script to load multiple keys:

```bash
KEY_PATH="/Users/sebos/.ssh/includes.d/"
KEYS=(
  "$KEY_PATH/rhel_jump/rhel_jump"
  "$KEY_PATH/github/github"
)

for key in "${KEYS[@]}"; do
    if [[ -f "$key" ]]; then
        if ssh-add "$key" 2>/dev/null; then
            echo "[+] Added: $key"
        else
            echo "[!] Skipped (already added or permission issue): $key"
        fi
    else
        echo "[!] Key file not found: $key"
    fi
done
```

---

## ✅ Testing GitHub SSH Access from a Remote Server

Once your SSH agent is loaded and you're connected to the remote host:

1. SSH into the remote server:

```bash
ssh sros
```

2. Test GitHub SSH access:

```bash
ssh -T git@github.com
```

If successful, you'll receive a message from GitHub confirming authentication.

3. To remove keys after use:

```bash
ssh-add -d <path_to_key>   # Remove specific key
ssh-add -D                 # Remove all keys
```

---

## 🔒 Security Concerns and Best Practices

While SSH Agent Forwarding is powerful, it also introduces potential security risks if misused. Use it thoughtfully and **disable access when not in use**.

### 🛡️ Best Practices for Secure SSH Agent Forwarding

| Practice                                                               | Why it Matters                |
| ---------------------------------------------------------------------- | ----------------------------- |
| ✅ Use `ForwardAgent yes` **only** for trusted hosts in `~/.ssh/config` | Avoids global exposure        |
| ✅ Disable agent forwarding on untrusted servers                        | Reduces lateral movement risk |
| ✅ Use `ProxyJump` with a hardened jump box                             | Contains exposure             |
| ✅ Remove keys from agent when not needed (`ssh-add -d/-D`)             | Minimizes attack window       |
| ✅ Audit agent socket activity                                          | Detects abuse attempts        |

You can also set a timeout for added security:

```bash
# Makes the key valid for only 1 hour
ssh-add -t 3600 <key_path>
```

---

## 🧩 Conclusion

With the rise of cloud infrastructure and **distributed application deployment**, protecting your **SSH private keys** while enabling remote operations is more critical than ever. By using **SSH Agent Forwarding**, you can maintain **secure access to GitHub** and other services without compromising key security on remote hosts.

This strategy is ideal for teams scaling deployments across environments while adhering to security best practices.
