# FTPS Load Balancing Troubleshooting Guide

## Problem Summary

When load balancing Implicit FTPS (port 990) traffic to IIS servers, Linux clients (using lftp) fail to connect through the Virtual IP (VIP), but direct connections to backend servers work correctly.

## Symptom

- **Works**: Direct connection to backend IIS server (even with DNS override in `/etc/hosts`)
- **Fails**: Connection through load balancer VIP
- **Client**: Linux with `lftp -u <user> ftps://<FQDN>`
- **Protocol**: Implicit FTPS on port 990
- **Typical failure**: Connection hangs after authentication, or "Making data connection... Failed"

## Root Cause

The issue stems from how FTP's dual-channel architecture (control + data) interacts with load balancing:

1. Client connects to VIP on port 990 for control channel
2. Client authenticates successfully
3. Client requests directory listing or file transfer
4. IIS responds with PASV command containing **its backend IP address** (not the VIP)
5. Because traffic is encrypted (Implicit FTPS), the load balancer cannot see or rewrite the PASV response
6. Linux client attempts to connect to the backend IP directly for data channel
7. Connection fails (backend IP unreachable, wrong routing, or hits different server)

### Why Direct Connection Works

When connecting directly to a backend server:
- Control channel connects to backend IP
- PASV response returns the same backend IP
- Data channel connects to same backend IP
- All traffic routes correctly to the same server

### Why VIP Connection Fails

When connecting through VIP:
- Control channel connects to VIP, forwarded to Backend Server A
- PASV response returns Backend Server A's IP (load balancer can't see/fix this due to encryption)
- Data channel attempts to connect to Backend Server A's IP directly
- Connection fails or routes incorrectly

## Traffic Flow Analysis

### Normal FTPS Connection Flow

```
Client                    VIP (Load Balancer)              Backend IIS
  |                              |                              |
  |--CONNECT 990--------------->|--CONNECT 990--------------->|
  |<---SSL Handshake-------------------------------------->   |
  |--USER username------------->|--USER username------------->|
  |--PASS password------------->|--PASS password------------->|
  |--LIST/PASV----------------->|--LIST/PASV----------------->|
  |<---227 (VIP_IP,port)--------|<---227 (VIP_IP,port)--------|
  |                              |                              |
  |--CONNECT VIP:50023--------->|--CONNECT Backend:50023----->|
  |<---File/Directory Data------------------------------------>|
```

### Broken Configuration Flow

```
Client                    VIP (Load Balancer)              Backend IIS
  |                              |                              |
  |--CONNECT 990--------------->|--CONNECT 990--------------->|
  |<---SSL Handshake-------------------------------------->   |
  |--USER username------------->|--USER username------------->|
  |--PASS password------------->|--PASS password------------->|
  |--LIST/PASV----------------->|--LIST/PASV----------------->|
  |<---227 (BACKEND_IP,port)----|<---227 (BACKEND_IP,port)----|
  |                              |                              |
  |--CONNECT BACKEND_IP:50023---------------------------> FAILS
  |    (unreachable/wrong route)
```

## Key Differences: Implicit vs Explicit FTPS

Understanding the mode is critical for troubleshooting:

| Feature | Explicit FTPS (Port 21) | Implicit FTPS (Port 990) |
|---------|------------------------|-------------------------|
| **Initial Connection** | Unencrypted | Encrypted from first byte |
| **Encryption Upgrade** | AUTH TLS command | Automatic |
| **Load Balancer Inspection** | Possible (before AUTH TLS) | Impossible (always encrypted) |
| **PASV Rewriting** | Load balancer can use FTP ALG | Load balancer is blind |
| **Fix Complexity** | Easier (LB can help) | Harder (IIS must be configured) |

**Your setup uses port 990 = Implicit FTPS**, which means the load balancer cannot inspect or modify FTP protocol commands.

## Complete Solution

### Step 1: Configure IIS FTP Firewall Support

This is the **critical fix**. IIS must be told to advertise the VIP address in PASV responses.

**On each IIS backend server:**

1. Open **IIS Manager**
2. Click the **server node** in the left tree (not a specific site, the server itself)
3. Double-click **"FTP Firewall Support"** (found in the Management section)
4. Configure the following:
   - **Data Channel Port Range**: `50000-50099` (or your preferred 100-port range)
   - **External IP Address of Firewall**: `<YOUR_VIP_IP_ADDRESS>`
     - ⚠️ **Use the IP address, NOT the FQDN**
     - ⚠️ **Use the VIP address, NOT the backend server IP**
5. Click **Apply**
6. Restart the FTP service:
   ```powershell
   net stop ftpsvc
   net start ftpsvc
   ```

**Alternative using PowerShell:**

```powershell
Import-Module WebAdministration

# Set the external IP (VIP)
Set-WebConfigurationProperty -PSPath "IIS:\\" -Filter "system.ftpServer/firewallSupport" -Name "externalIp4Address" -Value "<YOUR_VIP_IP>"

# Set the passive port range
Set-WebConfigurationProperty -PSPath "IIS:\\" -Filter "system.ftpServer/firewallSupport" -Name "lowDataChannelPort" -Value 50000
Set-WebConfigurationProperty -PSPath "IIS:\\" -Filter "system.ftpServer/firewallSupport" -Name "highDataChannelPort" -Value 50099

# Restart FTP service
Restart-Service ftpsvc
```

### Step 2: Configure Load Balancer

**Port Forwarding:**
- Forward port **990** (control channel) from VIP to backend servers
- Forward ports **50000-50099** (data channels) from VIP to backend servers

**Session Persistence/Affinity:**
- **Method**: Source IP persistence
- **Timeout**: Minimum 1800 seconds (30 minutes)
- **Purpose**: Ensures control and data connections reach the same backend server

**Health Checks:**
- **Type**: TCP health check
- **Port**: 990
- **Interval**: 10-30 seconds

**Load Balancing Method:**
- Least connections or round robin (your choice)
- Source IP persistence overrides this for active sessions

### Step 3: Firewall Configuration

If you have a separate firewall:

**Inbound Rules (Client → VIP):**
- Allow TCP port 990 (control channel)
- Allow TCP ports 50000-50099 (data channels)

**Outbound Rules (VIP → Backend):**
- Allow TCP port 990 to backend IIS servers
- Allow TCP ports 50000-50099 to backend IIS servers

### Step 4: IIS FTP Site Configuration

Verify each FTP site on IIS has correct SSL settings:

1. Open **IIS Manager**
2. Expand **Sites** → Select your FTP site
3. Double-click **FTP SSL Settings**
4. Ensure:
   - **SSL Certificate**: Valid certificate with VIP FQDN in CN or SAN
   - **SSL Policy**: "Require SSL connections" (for Implicit FTPS)
   - **Allow SSL Connections**: Checked

## Verification and Testing

### Test 1: Basic Connection Test

```bash
# Test basic connection and directory listing
lftp -u <user> -e "ls; bye" ftps://<FQDN>
```

**Expected**: Directory listing displays successfully

### Test 2: Debug Connection

```bash
# Run with full debugging
lftp -u <user> -e "debug 3; ls; bye" ftps://<FQDN> 2>&1 | tee ftps-debug.log

# Check for PASV responses
grep -E "227|229|Connecting data" ftps-debug.log
```

**Expected**: No errors about connection failures or timeouts

### Test 3: File Transfer Test

```bash
# Test upload
echo "test" > /tmp/test.txt
lftp -u <user> -e "put /tmp/test.txt; bye" ftps://<FQDN>

# Test download
lftp -u <user> -e "get test.txt -o /tmp/downloaded.txt; bye" ftps://<FQDN>
```

**Expected**: Both upload and download succeed

### Test 4: Verify IIS Configuration

On the IIS server, check the configuration was applied:

```powershell
# Check FTP Firewall Support settings
Get-WebConfigurationProperty -PSPath "IIS:\\" -Filter "system.ftpServer/firewallSupport" -Name "externalIp4Address"
Get-WebConfigurationProperty -PSPath "IIS:\\" -Filter "system.ftpServer/firewallSupport" -Name "lowDataChannelPort"
Get-WebConfigurationProperty -PSPath "IIS:\\" -Filter "system.ftpServer/firewallSupport" -Name "highDataChannelPort"
```

**Expected Output:**
```
externalIp4Address: <YOUR_VIP_IP>
lowDataChannelPort: 50000
highDataChannelPort: 50099
```

### Test 5: Monitor IIS FTP Logs

Enable FTP logging if not already enabled:

1. **IIS Manager** → **Sites** → Your FTP site → **FTP Logging**
2. Log file location: `C:\inetpub\logs\LogFiles\FTPSVC*\`

Look for successful PASV commands in the logs:
```
PASV - 227 Entering Passive Mode (x,x,x,x,p1,p2)
```

The IP should decode to your VIP address.

## Common Pain Points and Solutions

### Pain Point 1: PASV Response IP Mismatch ⚠️ CRITICAL

**Problem**: IIS returns backend IP in PASV responses instead of VIP
**Symptom**: Data connections fail or timeout
**Solution**: Configure IIS FTP Firewall Support with VIP IP (see Step 1)

### Pain Point 2: Data Channel Port Range Not Forwarded

**Problem**: Load balancer doesn't forward passive port range
**Symptom**: Control channel works, data channel times out
**Solution**: Forward ports 50000-50099 through load balancer

### Pain Point 3: Session Persistence Not Configured

**Problem**: Control and data connections hit different backend servers
**Symptom**: Authentication or transfer failures
**Solution**: Enable source IP persistence with 30+ minute timeout

### Pain Point 4: Certificate CN/SAN Mismatch

**Problem**: SSL certificate doesn't include VIP FQDN
**Symptom**: "Certificate verification: Not trusted" error
**Solution**: Install certificate with VIP FQDN in CN or SAN on all IIS servers

### Pain Point 5: Firewall Blocking Passive Ports

**Problem**: Firewall between client and VIP blocks high ports
**Symptom**: Hangs after authentication
**Solution**: Open ports 50000-50099 TCP on all firewalls in path

### Pain Point 6: TLS Version Mismatch

**Problem**: IIS configured for old TLS 1.0/1.1, client requires TLS 1.2+
**Symptom**: SSL handshake failures
**Solution**: Enable TLS 1.2/1.3 on IIS servers

### Pain Point 7: Active FTP Mode

**Problem**: Client tries active mode, which doesn't work through NAT
**Symptom**: Data connections fail
**Solution**: Force passive mode on client (lftp uses passive by default)

### Pain Point 8: Connection Timeout Too Short

**Problem**: Load balancer times out idle FTP connections
**Symptom**: Long transfers fail mid-transfer
**Solution**: Increase idle timeout to 30+ minutes

## Advanced Diagnostics

### Decode PASV Response

PASV responses look like: `227 Entering Passive Mode (h1,h2,h3,h4,p1,p2)`

**Decode**:
- **IP Address**: `h1.h2.h3.h4`
- **Port**: `(p1 × 256) + p2`

**Example**:
```
227 Entering Passive Mode (192,168,1,10,195,80)
IP: 192.168.1.10
Port: (195 × 256) + 80 = 49,920 + 80 = 50,000
```

### Packet Capture Analysis

If you can capture traffic on the IIS server:

```powershell
# On Windows Server, use netsh
netsh trace start capture=yes tracefile=C:\ftps-trace.etl maxsize=512

# Reproduce the issue, then stop
netsh trace stop

# Convert to pcap for analysis in Wireshark
# Use Microsoft Message Analyzer or etl2pcapng
```

Look for TCP connections to ports in range 50000-50099 that fail to establish.

### lftp Configuration for Troubleshooting

Create `~/.lftprc` or `~/.config/lftp/rc` with:

```bash
# Enable debugging
debug 3

# Increase timeouts
set net:timeout 30
set net:max-retries 2
set net:reconnect-interval-base 5

# Force passive mode
set ftp:passive-mode true

# SSL/TLS settings
set ftp:ssl-allow yes
set ftp:ssl-protect-data yes
set ftp:ssl-protect-list yes
set ftp:ssl-force yes

# For testing only - disable certificate verification
# set ssl:verify-certificate no

# Force IPv4
set dns:order inet
```

## Alternative Solutions

### Option 1: Switch to Explicit FTPS (Port 21)

If you can change protocols:

**Advantages**:
- Load balancer can use FTP ALG to rewrite PASV responses
- No need to configure IIS FTP Firewall Support
- More flexible load balancing options

**Disadvantages**:
- Requires client and server reconfiguration
- May not be allowed by security policy

### Option 2: Direct Server Return (DSR)

Advanced configuration where responses bypass the load balancer:

**How it works**:
1. Configure VIP on loopback interface of each IIS server
2. Load balancer forwards requests to backend
3. Backend responds directly to client (not through LB)

**Advantages**:
- Eliminates many load balancer issues
- Better performance for large transfers

**Disadvantages**:
- Complex configuration
- Requires routing changes
- Not supported by all load balancers

### Option 3: Layer 7 Load Balancer with SSL Termination

Use an application-aware load balancer:

**How it works**:
1. Load balancer terminates SSL connection
2. LB can inspect and rewrite FTP commands
3. LB creates new SSL connection to backend

**Advantages**:
- Can fix PASV responses automatically
- Centralized certificate management

**Disadvantages**:
- Higher CPU load on load balancer
- Additional SSL handshake latency
- Requires advanced load balancer features

## Recommended Architecture

```
                                    ┌─────────────────┐
                                    │   IIS Server 1  │
                                    │  Port 990       │
                                    │  Ports 50000-   │
                                    │        50099    │
                                    │  VIP in FTP FW  │
                                    └─────────────────┘
                                            ▲
                                            │
                                            │
┌──────────────┐      ┌────────────────────┼────────┐
│ Linux Client │      │   Load Balancer    │        │
│              │─────▶│   VIP: x.x.x.x    │        │
│ lftp         │      │   Port 990         │        │
└──────────────┘      │   Ports 50000-     │        │
                      │         50099      │        │
                      │   Source IP        │        │
                      │   Persistence      │        │
                      └────────────────────┼────────┘
                                            │
                                            │
                                            ▼
                                    ┌─────────────────┐
                                    │   IIS Server 2  │
                                    │  Port 990       │
                                    │  Ports 50000-   │
                                    │        50099    │
                                    │  VIP in FTP FW  │
                                    └─────────────────┘
```

**Key Configuration Points**:
1. All IIS servers configured with VIP as external IP
2. All IIS servers use same passive port range
3. Load balancer forwards all required ports
4. Source IP persistence ensures session affinity
5. Identical SSL certificates on all servers

## Troubleshooting Checklist

Use this checklist when issues occur:

- [ ] IIS FTP Firewall Support configured with VIP IP on all servers
- [ ] Passive port range (50000-50099) configured on all IIS servers
- [ ] FTP service restarted after configuration changes
- [ ] Load balancer forwards port 990 and ports 50000-50099
- [ ] Source IP persistence enabled with 30+ minute timeout
- [ ] SSL certificate includes VIP FQDN in CN or SAN
- [ ] Same SSL certificate installed on all backend servers
- [ ] Firewall allows ports 990 and 50000-50099 from clients to VIP
- [ ] Direct connection to backend works (verify IIS configuration)
- [ ] Connection through VIP works (verify load balancer configuration)
- [ ] FTP logs on IIS show successful PASV commands
- [ ] lftp debug output shows successful data connections

## Additional Resources

### Useful lftp Commands

```bash
# Test connection with detailed debug output
lftp -u <user> -e "debug 3; ls; bye" ftps://<FQDN>

# Test without SSL verification (troubleshooting only)
lftp -u <user> -e "set ssl:verify-certificate no; ls; bye" ftps://<FQDN>

# Force IPv4
lftp -u <user> -e "set dns:order inet; ls; bye" ftps://<FQDN>

# Test active mode (usually fails, but worth checking)
lftp -u <user> -e "set ftp:passive-mode false; ls; bye" ftps://<FQDN>

# Automated script with timeout
lftp -u <user> -e "set net:timeout 10; ls; bye" ftps://<FQDN>
```

### Windows FTP Client Testing

From Windows, test with PowerShell:

```powershell
# Basic connection test
$client = New-Object System.Net.WebClient
$client.Credentials = New-Object System.Net.NetworkCredential("username", "password")
$client.DownloadFile("ftps://<FQDN>/test.txt", "C:\temp\test.txt")
```

### IIS FTP Configuration Files

Configuration is stored in:
```
C:\Windows\System32\inetsrv\config\applicationHost.config
```

Look for the `system.ftpServer` section:
```xml
<system.ftpServer>
    <firewallSupport>
        <externalIp4Address value="<VIP_IP>" />
        <lowDataChannelPort value="50000" />
        <highDataChannelPort value="50099" />
    </firewallSupport>
</system.ftpServer>
```

## Summary

The key to successful FTPS load balancing with Implicit FTPS (port 990) is:

1. **IIS must advertise the VIP address** in PASV responses (FTP Firewall Support configuration)
2. **Load balancer must forward the passive port range** (50000-50099)
3. **Session persistence ensures** control and data connections reach the same server
4. **SSL certificates must be valid** for the VIP FQDN

Since Implicit FTPS encrypts all traffic from the first byte, the load balancer cannot inspect or modify FTP protocol commands. Therefore, IIS must be explicitly configured to return the correct IP address in PASV responses.

The fact that direct connections work but VIP connections fail is the classic symptom of this misconfiguration.

---

**Document Version**: 1.0
**Last Updated**: 2025-12-03
**Applies To**: Windows Server IIS FTP with Implicit FTPS (port 990), Linux lftp clients, Load balanced environments
