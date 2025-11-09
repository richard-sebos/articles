- Proxmox PVE serve and VM are on a seperate subnet than the home network
- firewall rules allow only access to a home lab jump box VM on the Proxmox sebnet.  This includes Proxmox VE SSH access
- systemctl stop/start pveproxy is used to stop and start the Proxmox web interface
- QubesOS Laptop had SSH auth keys created to use Yubico Key as second MFA to the used to log into  `hl_jump` jump box
- The SSH login is to a restricted user richard on the `hl_jump`
- I do allow SSH ProxyJump so from my laptop if you have, `hl_jump` SSH auth key, my Yubico Key and the SSH auth key for the Proxmox server you can use SSH to get to the PVE server
- SSH access to the Proxmox VE server is not allow from the `hl_jump`

- Here is the `sshd_config` .  I do have it broken into to seperate config files but I put it together here
# ------------------------------------------------------------------------------
# SECURITY & ACCESS CONTROL
# ------------------------------------------------------------------------------

# Use Pluggable Authentication Modules (PAM)
UsePAM yes

# Disable direct root login for better security
PermitRootLogin no

# Only allow users in the 'ssh-users' group to log in via SSH
AllowGroups ssh-users

# Do not allow login with empty passwords
PermitEmptyPasswords no

# Disable password and challenge-response authentication; enforce key-based logins
PasswordAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes

# Enforce strict permission checking on key files and home directories
StrictModes yes

# ------------------------------------------------------------------------------
# AUTHENTICATION RATE LIMITING & BRUTE-FORCE DEFENSE
# ------------------------------------------------------------------------------

# Maximum authentication attempts per connection
MaxAuthTries 3

# Limit concurrent unauthenticated connections to prevent brute-force attacks
# Format: start:rate:full (3 connections, then delay kicks in)
MaxStartups 3:30:10

# Limit number of multiplexed sessions per connection
MaxSessions 2

# Time limit for successful login to complete (0 disables grace time)
# Helps mitigate CVE-2024-6387
LoginGraceTime 0

# ------------------------------------------------------------------------------
# LOGGING & MONITORING
# ------------------------------------------------------------------------------

# Log extra details such as public key fingerprints and failed attempts
LogLevel VERBOSE

# Display last login time to users (also logged in system logs)
PrintLastLog yes

# Path to banner displayed before login
Banner /etc/ssh/sshd-banner

# ------------------------------------------------------------------------------
# SESSION & CONNECTION BEHAVIOR
# ------------------------------------------------------------------------------

# Send keep-alive message every 300 seconds (5 minutes)
ClientAliveInterval 300

# If no response to keep-alives, disconnect after 1 interval (i.e., 5 minutes)
ClientAliveCountMax 0

# Disable TCP keepalive probes from the server side
TCPKeepAlive no

# ------------------------------------------------------------------------------
# FORWARDING & TUNNELING CONTROLS
# ------------------------------------------------------------------------------

# Disable local socket forwarding (stream connections)
AllowStreamLocalForwarding no

# Disable SSH agent forwarding
AllowAgentForwarding no

# Disable tunneling (used for VPN-like tunnels)
PermitTunnel no

# Prevent remote clients from binding ports on the server
GatewayPorts no

# Disable X11 forwarding (graphical apps over SSH)
X11Forwarding no

```
