# FTPS Automated Testing Setup

## Overview

This setup creates a dedicated Linux user account that automatically runs comprehensive FTPS diagnostic tests when your teammate logs in. The tests run with full debug output and provide detailed analysis of the connection.

## Files Included

1. **ftps-auto-test.sh** - The main diagnostic test script
2. **setup-ftps-test-user.sh** - Setup script to create the test user
3. **README-Testing-Setup.md** - This file

## Quick Start

### Step 1: Prepare the Scripts

```bash
cd /home/user/Documents/claude/projects/f5

# Make scripts executable
chmod +x ftps-auto-test.sh
chmod +x setup-ftps-test-user.sh
```

### Step 2: Run the Setup Script

```bash
sudo ./setup-ftps-test-user.sh
```

The script will prompt you for:
- **FTPS Host (FQDN)**: Your VIP hostname (e.g., ftps.example.com)
- **FTPS Username**: The FTP username for testing
- **FTPS Password**: The FTP password for testing

### Step 3: Provide Login Details to Your Teammate

After setup completes, give your teammate:
- The test user's username (default: `ftpstest`)
- The generated password (displayed once during setup)
- Your server's hostname or IP

### Step 4: Your Teammate Logs In

```bash
ssh ftpstest@your-server.example.com
```

The diagnostic tests will run automatically!

## What Gets Created

### Test User Account

- **Username**: `ftpstest` (configurable)
- **Home Directory**: `/home/ftpstest`
- **Auto-run**: Tests execute automatically on login
- **Manual Commands**: Aliases for running tests manually

### Test Script Features

The automated test runs **7 comprehensive diagnostic tests**:

1. **DNS Resolution** - Verifies the FQDN resolves to correct VIP
2. **TCP Connectivity** - Tests port 990 is reachable
3. **SSL/TLS Handshake** - Validates certificate and encryption
4. **FTP Authentication** - Tests login credentials
5. **Directory Listing** - **Critical: Tests PASV data channel**
6. **File Upload** - Tests actual data transfer
7. **Connection Persistence** - Tests multiple operations

### Debug Output Included

- Full `lftp` debug output (level 3)
- PASV response decoding
- IP address comparison (VIP vs PASV)
- SSL certificate details
- Detailed error analysis
- Color-coded results

### Test Results

All test results are saved with timestamps:
- **Location**: `/tmp/ftps-test-results/`
- **Format**: `ftps-test-YYYYMMDD-HHMMSS.log`
- **Retention**: Manual cleanup (or configure log rotation)

## Manual Test Execution

After the initial auto-run, your teammate can:

```bash
# Run tests manually
ftps-test

# List recent test logs
ftps-logs

# View most recent test log
ftps-latest

# View specific log
cat /tmp/ftps-test-results/ftps-test-20251203-143022.log
```

## Understanding Test Results

### Success Indicators

```
✓ All tests passed!

The FTPS load balancer configuration appears to be working correctly.
Both control and data channels are functioning properly.
```

### Failure Indicators - PASV IP Mismatch

This is the **most common issue**:

```
✗ PASV IP does NOT match VIP - Configuration issue detected!
  Expected (VIP): 192.168.1.100
  Received (PASV): 10.20.30.40

⚠ This indicates IIS FTP Firewall Support is not configured correctly
  The backend IIS server is advertising its own IP instead of the VIP
```

**Solution**: Configure IIS FTP Firewall Support with VIP IP address

### Failure Indicators - Data Channel Timeout

```
✗ Directory listing failed

⚠ Timeout detected - likely data channel issue
  Possible causes:
  • PASV response contains backend IP instead of VIP
  • Passive port range not forwarded through load balancer
  • Firewall blocking passive ports (50000-50099)
  • Session persistence not configured on load balancer
```

## Customization

### Change FTPS Credentials

Edit the test script directly:

```bash
sudo -u ftpstest nano /home/ftpstest/ftps-auto-test.sh
```

Modify these lines:
```bash
FTPS_HOST="your-ftps-fqdn.example.com"
FTPS_USER="your-ftps-username"
FTPS_PASS="your-ftps-password"
```

### Disable Auto-Run

If you want to prevent automatic test execution on login:

```bash
sudo -u ftpstest nano /home/ftpstest/.bash_profile
```

Comment out the auto-run section or remove it entirely.

### Change Test User Name

Edit `setup-ftps-test-user.sh` before running:

```bash
TEST_USERNAME="your-custom-name"
```

### Add More Tests

The test script is modular. Add new test functions following this pattern:

```bash
test_your_new_test() {
    print_test "Test N: Your Test Description"

    # Your test logic here

    if [ $result -eq 0 ]; then
        print_success "Test passed"
        return 0
    else
        print_error "Test failed"
        return 1
    fi
}
```

Then call it in the main execution section.

## Security Considerations

### Password Storage

⚠️ **Important**: The FTPS password is stored in plaintext in the test script:
- File: `/home/ftpstest/ftps-auto-test.sh`
- Only readable by the `ftpstest` user (permissions: 755)

**Recommendations**:
1. Use a dedicated FTP test account with limited permissions
2. Restrict file permissions: `chmod 700 /home/ftpstest/ftps-auto-test.sh`
3. Delete the test user when testing is complete
4. Consider using SSH key authentication for the test user

### Test Account Isolation

The test user has:
- No sudo privileges
- Limited to running diagnostic tests
- No access to other user files
- Separate home directory

### Clean Up After Testing

When testing is complete, remove the test user:

```bash
# Delete user and home directory
sudo userdel -r ftpstest

# Remove test results
sudo rm -rf /tmp/ftps-test-results
```

## Troubleshooting the Test Setup

### Issue: "lftp: command not found"

**Solution**: Install lftp manually:

```bash
# Fedora/RHEL/CentOS
sudo dnf install lftp

# Debian/Ubuntu
sudo apt-get install lftp
```

### Issue: Test doesn't run automatically

**Check the .bash_profile**:
```bash
sudo cat /home/ftpstest/.bash_profile
```

Ensure it contains the auto-run code.

**Check if it's being sourced**:
```bash
sudo -u ftpstest bash -l -c 'echo $FTPS_TEST_RAN'
```

Should output "1" after login.

### Issue: Permission denied errors

**Fix script permissions**:
```bash
sudo chmod +x /home/ftpstest/ftps-auto-test.sh
sudo chown ftpstest:ftpstest /home/ftpstest/ftps-auto-test.sh
```

### Issue: Can't read test results

**Fix directory permissions**:
```bash
sudo chown ftpstest:ftpstest /tmp/ftps-test-results
sudo chmod 755 /tmp/ftps-test-results
```

## Sample Output

Here's what your teammate will see on login:

```
Running automated FTPS diagnostic tests...
Please wait...

╔════════════════════════════════════════════════════════════════╗
║     FTPS Load Balancer Diagnostic Test Suite                  ║
╚════════════════════════════════════════════════════════════════╝

Test started: Wed Dec  3 14:30:22 PST 2025
Testing host: ftps.example.com
Log file: /tmp/ftps-test-results/ftps-test-20251203-143022.log

═══════════════════════════════════════════════════════════════
  Checking Prerequisites
═══════════════════════════════════════════════════════════════

✓ All required tools are installed

═══════════════════════════════════════════════════════════════
  Running Diagnostic Tests
═══════════════════════════════════════════════════════════════

▶ Test 1: DNS Resolution
✓ Resolved ftps.example.com to 192.168.1.100
  VIP Address: 192.168.1.100

▶ Test 2: TCP Connectivity to Port 990
✓ TCP connection to ftps.example.com:990 successful

▶ Test 3: SSL/TLS Handshake
✓ SSL/TLS handshake successful
  Subject: CN=ftps.example.com
  Issuer: CN=Example CA
  notBefore=Dec  1 00:00:00 2025 GMT
  notAfter=Dec  1 00:00:00 2026 GMT
✓ Certificate verification: PASSED

▶ Test 4: Basic FTP Connection and Authentication
✓ FTP authentication successful

▶ Test 5: Directory Listing (Tests PASV Data Channel)

This test will show if the data channel can be established.
Look for the PASV response and data connection attempts.

--- BEGIN DEBUG OUTPUT ---
[... detailed lftp debug output ...]
<--- 227 Entering Passive Mode (192,168,1,100,195,80)
---- Connecting data socket to (192.168.1.100) port 50000
[... more debug output ...]
--- END DEBUG OUTPUT ---

✓ Directory listing successful

ℹ PASV Response Found:
  227 Entering Passive Mode (192,168,1,100,195,80)
  Decoded IP: 192.168.1.100
  Decoded Port: 50000
✓ PASV IP matches VIP - Configuration is CORRECT!

[... remaining tests ...]

═══════════════════════════════════════════════════════════════
  Test Summary and Recommendations
═══════════════════════════════════════════════════════════════

Test Results:
  Passed: 7
  Failed: 0

✓ All tests passed!

The FTPS load balancer configuration appears to be working correctly.
Both control and data channels are functioning properly.

Documentation:
  See FTPS-Load-Balancing-Troubleshooting.md for complete setup guide

Log File:
  /tmp/ftps-test-results/ftps-test-20251203-143022.log

Test completed: Wed Dec  3 14:31:45 PST 2025

Press Enter to continue or Ctrl+C to exit
```

## Integration with CI/CD

You can also run this test script in automated environments:

```bash
# Non-interactive mode (auto-exit after test)
sed -i 's/read -r$/# read -r/' /home/ftpstest/ftps-auto-test.sh

# Run and capture exit code
/home/ftpstest/ftps-auto-test.sh
if [ $? -eq 0 ]; then
    echo "FTPS tests passed"
else
    echo "FTPS tests failed"
fi
```

## Additional Resources

- **Full troubleshooting guide**: `FTPS-Load-Balancing-Troubleshooting.md`
- **Test logs**: `/tmp/ftps-test-results/`
- **lftp documentation**: `man lftp` or https://lftp.yar.ru/

## Support

If issues persist after testing:

1. Review the detailed log output
2. Check the troubleshooting guide (FTPS-Load-Balancing-Troubleshooting.md)
3. Verify IIS FTP Firewall Support configuration
4. Verify load balancer configuration
5. Check firewall rules

---

**Created**: 2025-12-03
**Version**: 1.0
**Compatible with**: Fedora, RHEL, CentOS, Debian, Ubuntu
