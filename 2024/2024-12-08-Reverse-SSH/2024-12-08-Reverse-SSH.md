

# **Understanding SSH and Reverse SSH — A Beginner’s Guide**

When I first started using SSH (Secure Shell), it felt straightforward: open a terminal, run a command, and connect to a remote server. SSH was my go-to tool for securely running commands and managing servers over a network.

Over time, I learned about SSH features like jump hosts and port forwarding, which can create encrypted tunnels between machines. In the standard model, you start from your local machine and connect outward to a remote system.

But what happens when your local machine **can’t** connect to that remote system directly — maybe because of strict firewalls or NAT restrictions?
That’s where **Reverse SSH** comes in.

---

## **Table of Contents**

1. [Introduction](#introduction)
2. [What Is Reverse SSH?](#what-is-reverse-ssh)
3. [Setting Up Reverse SSH](#setting-up-reverse-ssh)

   * [Restricting Access](#restricting-access)
   * [Starting the Reverse SSH Connection](#starting-the-reverse-ssh-connection)
4. [Why Use Reverse SSH?](#why-use-reverse-ssh)
5. [Conclusion](#conclusion)

---

## **What Is Reverse SSH?**

Normally, SSH connections start from a **local machine** to a **remote server**. But sometimes that path is blocked by firewall rules, NAT, or limited inbound access.

Reverse SSH flips this around: **the remote device initiates the SSH connection back to the local device**, creating a secure tunnel that the local device can then use to communicate with the remote one.

**Key principle:**
Most networks allow return traffic for outbound connections. Reverse SSH takes advantage of this by having the remote device open the connection first.

---

### **Visual Example**

```text
   Local Device (192.168.178.19)         Remote Device (192.168.178.17)
           +---------+                                +---------+
           |         |                                |         |
           |   SSH   |<-- Tunnel (Port 7000) -- SSH --|   SSH   |
           | Client  |                                | Server  |
           +---------+                                +---------+
                  ^
                  |
                  +---------( Initiated from Remote )
```

---

## **Setting Up Reverse SSH**

I tested Reverse SSH using three devices:

* **Remote device:** `192.168.178.17` → Initiates the Reverse SSH connection.
* **Local device:** `192.168.178.19` → Uses the tunnel to access the remote device.
* **Testing device:** `192.168.178.10` → Always has direct SSH access to the remote device.

Initially, both the local and testing devices could SSH directly into the remote device.

---

### **Restricting Access**

To simulate a real-world block, I configured the firewall on the remote device to allow SSH only from the testing device:

```bash
sudo ufw allow from 192.168.178.10 to any port 22
sudo ufw deny 22
sudo ufw enable
```

After applying these rules, the local device could no longer connect directly to the remote device.

---

### **Starting the Reverse SSH Connection**

From the remote device, I ran:

```bash
ssh -R 7000:localhost:22 richard@192.168.178.19
```

**Explanation:**

* `-R 7000:localhost:22` → Forwards port 22 from the remote device through the tunnel to port 7000 on the local device.

Now, from the **local device**, I could connect through the tunnel:

```bash
ssh richard@localhost -p 7000
```

To run the Reverse SSH session in the background:

```bash
ssh -f -N -R 7000:localhost:22 richard@192.168.178.19
```

**Flags:**

* `-f` → Run in the background after authentication.
* `-N` → Don’t execute remote commands; useful for port forwarding only.

---

## **Why Use Reverse SSH?**

Reverse SSH is useful when:

* Managing **IoT devices** or remote systems behind restrictive firewalls.
* Accessing servers without exposing port 22 to the entire internet.
* Automating remote maintenance or troubleshooting without opening inbound rules.

**Security tip:**
Even if firewall rules allow it, you can restrict Reverse SSH with:

```bash
AllowUsers richard@192.168.178.10
```

Other security measures:

* Use `PermitOpen` to limit which ports can be forwarded.
* Keep `GatewayPorts` disabled unless absolutely necessary.
* Use key-based authentication and disable password logins.

---

## **Conclusion**

Reverse SSH is a powerful technique for working around restrictive network environments while keeping your connections secure. By flipping the connection direction, you can access remote devices that would otherwise be unreachable.

Whether for automation, troubleshooting, or managing devices in the field, it’s a tool worth adding to your SSH skill set.

