
# Using **chroot** to Restrict Linux Applications for Enhanced Security

## Table of Contents

1. [Introduction](#introduction)
2. [Understanding chroot](#understanding-chroot)
3. [Why Use chroot with SSH](#why-use-chroot-with-ssh)
4. [Risks and Limitations of chroot](#risks-and-limitations-of-chroot)
5. [How It Works: A Practical Example](#how-it-works-a-practical-example)

   * [Creating the Isolated Filesystem](#creating-the-isolated-filesystem)
   * [Setting Up the Limited Application](#setting-up-the-limited-application)
   * [SSH Configuration Changes](#ssh-configuration-changes)
6. [Final Thoughts](#final-thoughts)

---

## Introduction

Modern Linux distributions often include hundreds or even thousands of individual programs. Each one of these programs adds another potential entry point for malicious actors seeking to compromise your system. This raises an important question: what if you could run an application in isolation, without the need to introduce even more applications or dependencies? This is where Linux’s **chroot** feature becomes extremely valuable.

---

## Understanding **chroot**

Linux provides a powerful capability known as **chroot**. This feature allows administrators to create an isolated section of the filesystem and treat it as the root directory for a given set of processes. By doing so, you can build a restricted environment containing only the necessary components for a specific task or application. Anything outside this isolated filesystem is effectively invisible and inaccessible to the user and any processes running within the chroot. While this might seem highly restrictive, it’s precisely this limitation that makes **chroot** a valuable tool for improving security.

---

## Why Use **chroot** with SSH

The main reason to leverage **chroot** in conjunction with SSH is precisely because of its restrictive nature. Once a chroot environment is properly set up, logging in via SSH confines the user to a controlled subset of the system. For example, after setting up the environment described below, even common commands such as `ls` and `sleep` were initially unavailable until explicitly added along with their required libraries. SSH access into this kind of chrooted environment results in an extremely limited session where only the desired tools and commands are exposed. This begs the question: why isn’t this used more often?

---

## Risks and Limitations of **chroot**

While **chroot** is a useful tool, it works best with applications that are either fully self-contained or rely on only a small number of additional libraries or utilities. A key consideration is that all required binaries and libraries must physically exist within the chroot environment as copies, not as symbolic links. This requirement introduces maintenance overhead because any updates made to the system’s primary locations (such as through patching) do not automatically propagate to these copies. Without a process to manage updates within the chroot, the environment can become outdated, defeating its security purpose.

---

## How It Works: A Practical Example

Recently, I worked on a project where remote users needed limited access to a Linux system via SSH. To determine whether **chroot** would meet the project’s needs, I created a test environment with the following setup.

### Creating the Isolated Filesystem

The chroot root directory was established at `/home/jail`, and a dedicated user account named `app_richard` was created. It’s important to note that `/home/jail` contains directories and is not itself a user account. The directory structure looked like this:

```bash
/home
├── jail
│   ├── app
│   ├── home
│   │   └── app_richard
├── app_richard 
```

All files and directories under `/home/jail` were owned by root to ensure proper isolation.

### Setting Up the Limited Application

When the user logs in via SSH, a script called `launch_app.sh` is executed. This script is stored at `/home/jail/app/launch_app.sh` and contains the following:

```bash
#!/bin/bash

echo "==========================================="
echo " Welcome to the Chroot Test App"
echo "==========================================="

echo ""
echo "You are currently in: $(pwd)"
echo "Listing contents of your home directory:"
echo ""

ls -la /home/app_richard

echo ""
echo "Test complete. Disconnecting now..."
sleep 3
exit 0
```

For this script to function, the chroot environment needed to include copies of `bash`, `ls`, `sleep`, and the shared libraries required to run them. The `ldd` command was useful for identifying the libraries needed: 

```bash
ldd /usr/bin/bash
```

Commands such as `echo` and `exit` are built into `bash`.

After copying the necessary binaries and libraries into a directory structure mirroring the host system, the chroot environment appeared as follows:

```bash
/home
├── jail
│   ├── app
│   │   └── launch_app.sh
│   ├── bin
│   │   └── bash
│   ├── home
│   │   └── app_richard
│   ├── lib64
│   │   ├── ld-linux-x86-64.so.2
│   │   ├── libcap.so.2
│   │   ├── libc.so.6
│   │   ├── libdl.so.2
│   │   ├── libpcre2-8.so.0
│   │   ├── libpthread.so.0
│   │   ├── libselinux.so.1
│   │   └── libtinfo.so.6
│   └── usr
│       └── bin
│           ├── ls
│           └── sleep
├── app_richard 
```

Since multiple users were intended to access this environment, I created a user group named `app_users` to manage permissions consistently.

### SSH Configuration Changes

SSH configuration adjustments were straightforward. I appended the following block to the end of the `sshd_config` file:

```bash
## added to the end
Match Group app_users
ChrootDirectory /home/jail
ForceCommand /app/launch_app.sh
PermitTTY no
AllowTcpForwarding no
X11Forwarding no
```

After restarting the SSH service with:

```bash
sudo systemctl restart sshd
```

the login experience appeared as expected:

```bash
===========================================
 Welcome to the Chroot Test App
===========================================

You are currently in: /home/app_richard
Listing contents of your home directory:

total 0
drwxr-xr-x. 2 1003 1004  6 Jul 18 01:25 .
drwxr-xr-x. 3    0    0 18 Jul 18 01:25 ..

Test complete. Disconnecting now...
```

---

## Final Thoughts

If you plan to use **chroot**, it’s critical to establish processes for rebuilding these environments after system updates. Without this, the chroot environment will not receive necessary updates, leaving outdated libraries and binaries in place, which defeats the purpose of creating a secure, isolated environment.

Would I recommend using **chroot**? Absolutely—but only in specific scenarios. If I can confine a Python application using `venv` or I am working with a well-defined third-party application, **chroot** makes sense. However, always remember: **chroot** remaps the filesystem but does not constitute a full security boundary. Additional measures are still required to secure memory, networking, and other system resources.

**Need Linux expertise?** I help businesses streamline servers, secure infrastructure, and automate workflows. Whether you're troubleshooting, optimizing, or building from scratch—I've got you covered.  
📬 Drop a comment or [email me](mailto:info@sebostechnology.com) to collaborate. For more tutorials, tools, and insights, visit [sebostechnology.com](https://sebostechnology.com).