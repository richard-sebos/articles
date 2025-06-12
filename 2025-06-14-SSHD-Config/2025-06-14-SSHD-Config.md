
## Connection Limiting

This configuration hardens the SSH server by enforcing strict session timeouts, mitigating CVE-2024-6387, and limiting unauthenticated connection attempts to reduce the risk of brute-force attacks.

```bash
# -----------------------------
# SSH Session Timeout Settings
# -----------------------------

# Sends a "keepalive" message every 300 seconds (5 minutes) to verify the client is still responsive.
ClientAliveInterval 300

# If the client fails to respond to 0 keepalive messages (i.e., first failure triggers disconnect).
# Setting this to 0 means the connection will be closed immediately after the first missed response.
ClientAliveCountMax 0

# Disables TCP keepalive messages at the operating system level to reduce potential detection/exploitation.
TCPKeepAlive no


# -----------------------------
# CVE Mitigation
# -----------------------------

# Set to 0 to immediately drop unauthenticated connections that don't complete login,
# mitigating CVE-2024-6387 (a race condition in login grace handling).
LoginGraceTime 0


# -----------------------------
# Brute-force Mitigation
# -----------------------------

# Limits unauthenticated SSH connection attempts:
# - Allows 3 unauthenticated connections initially.
# - Gradually throttles new connection attempts (up to 30) using a rate of 1 every 10 seconds.
MaxStartups 3:30:10

```


## Linit Login

This configuration block enforces key-based SSH access, disables root and insecure logins, limits user access to a specific group, and strengthens authentication controls and file permission checks to 

```bash
# -----------------------------------------
# Root Access and Group-Based Restrictions
# -----------------------------------------

# Disables direct SSH login as root user to reduce risk of privileged account compromise.
PermitRootLogin no

# Only users belonging to the 'ssh-users' group are allowed to connect via SSH.
# This enables centralized access control using Unix groups.
AllowGroups ssh-users


# -------------------------------
# Basic Authentication Hardening
# -------------------------------

# Prevents users from logging in with empty passwords.
PermitEmptyPasswords no

# Limits the number of authentication attempts per connection to 3.
# Helps prevent brute-force password guessing attacks.
MaxAuthTries 3

# Restricts the number of concurrent open sessions per connection to 2.
# Useful to prevent abuse of multiplexed SSH sessions.
MaxSessions 2


# ----------------------------------------------
# Enforce Key-Based Authentication (No Passwords)
# ----------------------------------------------

# Disables traditional password-based login.
# Only public key authentication will be accepted.
PasswordAuthentication no

# Disables challenge-response (e.g., keyboard-interactive) authentication.
# Further enforces exclusive use of key-based login.
ChallengeResponseAuthentication no


# -------------------------------------
# Enforce Secure File Permissions Checks
# -------------------------------------

# Enables strict checking of user's ~/.ssh and related file permissions.
# Prevents logins if insecure permissions are detected, reducing the risk of key theft.
StrictModes yes

```

## Overwrite Limitation of needed

This configuration restricts SSH access to trusted IP ranges and user groups, with optional per-IP rules, while relying on the firewall to block all other unauthorized sources.

```bash
## Login Overrides
# -----------------------------------------------
# SSH Access Control by IP Address or Subnet
# -----------------------------------------------

# Allow SSH access **only** from trusted internal networks:
# - 192.168.100.0/24: typical internal subnet
# - 10.0.0.0/8: private network range
# Only members of the 'ssh-users' group from these IP ranges will be allowed.
Match Address 192.168.100.0/24,10.0.0.0/8
    AllowGroups ssh-users

# -------------------------------------------------------
# Optional: Apply additional restrictions to specific IPs
# -------------------------------------------------------

# Uncomment and customize to enforce stricter rules per host or IP.
# For example, enforce no root login and key-based authentication only
# for a specific host (192.168.100.50):
#
# Match Address 192.168.100.50
#     PermitRootLogin no
#     PasswordAuthentication no

# ------------------------------------------------------------------
# Note: Denying access from all other IPs is **not** handled here.
# ------------------------------------------------------------------
# sshd_config does not support a "deny all except" approach.
# To block untrusted IPs, use a firewall (e.g., firewalld, nftables, or iptables)
# to explicitly allow known IPs and drop everything else at the network level.

```

##

```bash
# ---------------------------------------------
# Disable All SSH Forwarding and Tunneling
# ---------------------------------------------

# Disables TCP port forwarding to prevent users from creating encrypted tunnels
# that could be used to bypass firewalls or access internal services.
AllowTcpForwarding no

# Disables Unix domain socket forwarding (e.g., for interprocess communication).
# Adds an additional layer of restriction for local stream forwarding.
AllowStreamLocalForwarding no

# Prevents forwarding of the SSH authentication agent.
# Protects against credential theft via agent hijacking on shared systems.
AllowAgentForwarding no

# Disables creation of VPN-like tunnels using SSH.
# Helps enforce strict network boundaries and prevent lateral movement.
PermitTunnel no

# Prevents binding forwarded ports to non-loopback addresses (e.g., 0.0.0.0),
# which could expose services to external networks if port forwarding were enabled.
GatewayPorts no

# Disables X11 forwarding to block graphical interface redirection over SSH,
# reducing risk of remote GUI attacks or accidental exposure.
X11Forwarding no


```


##
This setting is needed to prevent users from injecting environment variables that could alter SSH session behavior or bypass security controls, reducing the risk of privilege escalation or command manipulation.


```bash
# ------------------------------------------------------------
# Disable User-Controlled Environment Variables
# ------------------------------------------------------------

# Prevents users from setting environment variables via ~/.ssh/environment
# or through SSH commands, which could be exploited to alter execution behavior,
# bypass security policies, or inject malicious settings.
PermitUserEnvironment no

```