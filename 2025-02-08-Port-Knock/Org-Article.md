

## **Introduction**  

Securing SSH access is critical for **home lab users** and **new system administrators** looking to protect their remote servers. One effective way to enhance security is **Port Knocking**, a technique that keeps SSH access hidden until a predefined sequence of connection attempts (or "knocks") is made on specific ports. When the correct sequence is detected, the firewall dynamically allows SSH access.  

---

# **Table of Contents**  

1. [Introduction](#introduction)  
2. [Understanding Port Knocking](#understanding-port-knocking)  
3. [Installing and Configuring knockd](#installing-and-configuring-knockd)  
   - [Step 1: Install knockd](#step-1-install-knockd)  
   - [Step 2: Edit the knockd Configuration File](#step-2-edit-the-knockd-configuration-file)  
   - [Step 3: Enable knockd on Startup](#step-3-enable-knockd-on-startup)  
4. [Adjusting Firewall Rules](#adjusting-firewall-rules)  
   - [Allow Established Connections](#allow-established-connections)  
   - [Block SSH by Default](#block-ssh-by-default)  
5. [Enabling and Starting knockd with systemctl](#enabling-and-starting-knockd-with-systemctl)  
   - [Reload Systemd Daemon](#reload-systemd-daemon)  
   - [Enable knockd to Start at Boot](#enable-knockd-to-start-at-boot)  
   - [Start the knockd Service](#start-the-knockd-service)  
   - [Verify knockd Status](#verify-knockd-status)  
6. [Testing Port Knocking](#testing-port-knocking)  
7. [Next Steps: Automating Port Knocking](#next-steps-automating-port-knocking)  

📌 **Read Part 2: [Automating Port Knocking with Dynamic Port Rotation](#)**  

### Part of the [Ethical Hacking Robot Project](https://dev.to/sebos/hacking-robot-needed-raspberry-pi-need-not-apply-49l6)
---


By the end of this tutorial, you’ll have a **fully functional Port Knocking setup**, ensuring that your SSH server remains hidden from unauthorized access.  

---

## **1. Understanding Port Knocking**  

By default, your SSH service listens on port **22**, which makes it an easy target for **brute-force attacks** and **port scanning**. With **Port Knocking**, your SSH port remains **closed** unless a specific **sequence of connection attempts** is made on predefined ports. Once the correct sequence is received, the firewall temporarily opens SSH access for the client.  

---

## **2. Installing and Configuring knockd**  

### **Step 1: Install knockd**  

For **Debian/Ubuntu**, install `knockd` with:  

```bash
sudo apt update && sudo apt install knockd -y
```  

For **CentOS/RHEL**, use:  

```bash
sudo yum install knock -y
```  

---

### **Step 2: Edit the knockd Configuration File**  

Modify `/etc/knockd.conf` to define the **knocking sequence** and the commands to open or close SSH access:  

```bash
### Open SSH Access  
[openSSH]  
    sequence = 60842,31027,56118  
    seq_timeout = 5  
    command     = /sbin/iptables -I INPUT -s %IP% -p tcp --dport 22 -j ACCEPT  
    tcpflags    = syn  

### Close SSH Access  
[closeSSH]  
    sequence    = 56118,31027,60842  
    seq_timeout = 5  
    command     = /sbin/iptables -D INPUT -s %IP% -p tcp --dport 22 -j ACCEPT  
    tcpflags    = syn  
```  

💡 **Tip:** You can modify the `sequence` values to any ports of your choice for additional security.  

---

### **Step 3: Enable knockd on Startup**  

Edit `/etc/default/knockd` to ensure the service runs on boot:  

```bash
START_KNOCKD=1  
KNOCKD_OPTS="-i ens18"
```  

💡 **Tip:** Use `ip a` to find your network interface if unsure.  

---

## **3. Adjusting Firewall Rules**  

Before enabling Port Knocking, modify your **iptables** rules:  

### ✅ **Allow Established Connections**  

To prevent active SSH sessions from being interrupted:  

```bash
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```  

### ❌ **Block SSH by Default**  

Until the correct knock sequence is received, **block all SSH traffic**:  

```bash
sudo iptables -A INPUT -p tcp --dport 22 -j REJECT
```  

---

## **4. Enabling and Starting knockd with systemctl**  

### **Reload Systemd Daemon**  

```bash
sudo systemctl daemon-reload
```  

### **Enable knockd to Start at Boot**  

```bash
sudo systemctl enable knockd
```  

### **Start the knockd Service**  

```bash
sudo systemctl start knockd
```  

### **Verify knockd Status**  

```bash
sudo systemctl status knockd
```  

If successful, you should see **"active (running)"**. 🚀  

---

## **5. Testing Port Knocking**  

From your **client machine**, install `knock` and send the **openSSH** sequence:  

```bash
knock -v your-server-ip 60842 31027 56118
```  

Now, try **SSH access**:  

```bash
ssh user@your-server-ip
```  

To **lock SSH** again:  

```bash
knock -v your-server-ip 56118 31027 60842
```  

Your **SSH access should now be revoked**! 🎉  

---

## **Next Steps: Automating Port Knocking**  

While this setup is effective, **using the same knock sequence indefinitely** can pose a security risk. A more advanced approach involves **automatically rotating knock sequences** using a **systemd timer**.  

📌 **Read Part 2: [Automating Port Knocking with Dynamic Port Rotation](https://dev.to/sebos/automate-port-knocking-with-dynamic-port-rotation-for-secure-ssh-access-pbh)**  

[code and config files there](https://github.com/richard-sebos/Ethical-Hacking-Robot/blob/main/SSH/knockd_readme.md)
These two articles should now be **separate and more digestible** for readers. Let me know if you need any tweaks before publishing! 🚀