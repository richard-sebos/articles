#!/bin/bash
################################################################################
# FTPS Test User Setup Script
# Purpose: Create a dedicated test user that automatically runs FTPS diagnostics
# Usage: sudo ./setup-ftps-test-user.sh
################################################################################

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Configuration
TEST_USERNAME="ftpstest"
TEST_USER_HOME="/home/${TEST_USERNAME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${BLUE}  FTPS Test User Setup Script${NC}"
echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Prompt for FTPS connection details
echo -e "${BOLD}Please provide FTPS connection details:${NC}"
echo ""

read -p "FTPS Host (FQDN): " FTPS_HOST
read -p "FTPS Username: " FTPS_USER
read -sp "FTPS Password: " FTPS_PASS
echo ""
echo ""

# Validate inputs
if [ -z "$FTPS_HOST" ] || [ -z "$FTPS_USER" ] || [ -z "$FTPS_PASS" ]; then
    echo -e "${RED}Error: All fields are required${NC}"
    exit 1
fi

echo -e "${YELLOW}Creating test user: ${TEST_USERNAME}${NC}"

# Check if user already exists
if id "$TEST_USERNAME" &>/dev/null; then
    echo -e "${YELLOW}Warning: User ${TEST_USERNAME} already exists${NC}"
    read -p "Do you want to reconfigure this user? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
else
    # Create the user
    echo "Creating user account..."
    useradd -m -s /bin/bash "$TEST_USERNAME"

    # Set a random password (user will primarily use SSH keys or you can set it)
    echo "Setting user password..."
    RANDOM_PASS=$(openssl rand -base64 12)
    echo "${TEST_USERNAME}:${RANDOM_PASS}" | chpasswd

    echo -e "${GREEN}✓ User created${NC}"
    echo "  Username: ${TEST_USERNAME}"
    echo "  Password: ${RANDOM_PASS}"
    echo "  (Save this password - it won't be shown again)"
    echo ""
fi

# Install required packages if not present
echo "Checking required packages..."
PACKAGES_TO_INSTALL=()

if ! command -v lftp &> /dev/null; then
    PACKAGES_TO_INSTALL+=("lftp")
fi

if ! command -v openssl &> /dev/null; then
    PACKAGES_TO_INSTALL+=("openssl")
fi

if ! command -v nc &> /dev/null && ! command -v netcat &> /dev/null; then
    PACKAGES_TO_INSTALL+=("netcat")
fi

if [ ${#PACKAGES_TO_INSTALL[@]} -ne 0 ]; then
    echo "Installing required packages: ${PACKAGES_TO_INSTALL[*]}"

    # Detect package manager
    if command -v dnf &> /dev/null; then
        dnf install -y "${PACKAGES_TO_INSTALL[@]}"
    elif command -v yum &> /dev/null; then
        yum install -y "${PACKAGES_TO_INSTALL[@]}"
    elif command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y "${PACKAGES_TO_INSTALL[@]}"
    else
        echo -e "${RED}Error: Could not detect package manager${NC}"
        echo "Please install manually: ${PACKAGES_TO_INSTALL[*]}"
        exit 1
    fi

    echo -e "${GREEN}✓ Packages installed${NC}"
else
    echo -e "${GREEN}✓ All required packages already installed${NC}"
fi

# Copy the test script to user's home
echo "Installing test script..."
cp "${SCRIPT_DIR}/ftps-auto-test.sh" "${TEST_USER_HOME}/"
chown "${TEST_USERNAME}:${TEST_USERNAME}" "${TEST_USER_HOME}/ftps-auto-test.sh"
chmod +x "${TEST_USER_HOME}/ftps-auto-test.sh"

# Update the script with actual credentials
echo "Configuring test script with credentials..."
sed -i "s|FTPS_HOST=\".*\"|FTPS_HOST=\"${FTPS_HOST}\"|" "${TEST_USER_HOME}/ftps-auto-test.sh"
sed -i "s|FTPS_USER=\".*\"|FTPS_USER=\"${FTPS_USER}\"|" "${TEST_USER_HOME}/ftps-auto-test.sh"
sed -i "s|FTPS_PASS=\".*\"|FTPS_PASS=\"${FTPS_PASS}\"|" "${TEST_USER_HOME}/ftps-auto-test.sh"

echo -e "${GREEN}✓ Test script installed and configured${NC}"

# Create .bash_profile to auto-run the test
echo "Configuring auto-run on login..."
cat > "${TEST_USER_HOME}/.bash_profile" << 'EOF'
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# Auto-run FTPS test on login
if [ -t 0 ] && [ -z "$FTPS_TEST_RAN" ]; then
    export FTPS_TEST_RAN=1
    echo ""
    echo "Running automated FTPS diagnostic tests..."
    echo "Please wait..."
    echo ""
    sleep 2
    ~/ftps-auto-test.sh
fi
EOF

chown "${TEST_USERNAME}:${TEST_USERNAME}" "${TEST_USER_HOME}/.bash_profile"
chmod 644 "${TEST_USER_HOME}/.bash_profile"

echo -e "${GREEN}✓ Auto-run configured${NC}"

# Create a .bashrc if it doesn't exist
if [ ! -f "${TEST_USER_HOME}/.bashrc" ]; then
    cat > "${TEST_USER_HOME}/.bashrc" << 'EOF'
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific aliases and functions
alias ll='ls -la'
alias ftps-test='~/ftps-auto-test.sh'
alias ftps-logs='ls -lth /tmp/ftps-test-results/*.log | head -10'
alias ftps-latest='cat $(ls -t /tmp/ftps-test-results/*.log | head -1)'

# Show helper information
echo ""
echo "FTPS Test User Environment"
echo "=========================="
echo "Commands available:"
echo "  ftps-test   - Run FTPS diagnostic tests manually"
echo "  ftps-logs   - List recent test logs"
echo "  ftps-latest - View most recent test log"
echo ""
EOF

    chown "${TEST_USERNAME}:${TEST_USERNAME}" "${TEST_USER_HOME}/.bashrc"
    chmod 644 "${TEST_USER_HOME}/.bashrc"
fi

# Create initial test results directory
mkdir -p /tmp/ftps-test-results
chown "${TEST_USERNAME}:${TEST_USERNAME}" /tmp/ftps-test-results
chmod 755 /tmp/ftps-test-results

# Create a README for the test user
cat > "${TEST_USER_HOME}/README.txt" << EOF
FTPS Test User Guide
====================

This account is configured to automatically test FTPS connectivity
when you log in.

FTPS Connection Details:
  Host: ${FTPS_HOST}
  User: ${FTPS_USER}

The test will run automatically when you log in via SSH or console.

Manual Commands:
  ftps-test   - Run the diagnostic tests manually
  ftps-logs   - List recent test logs
  ftps-latest - View the most recent test log

Test Results:
  All test results are saved in: /tmp/ftps-test-results/
  Log files are named: ftps-test-YYYYMMDD-HHMMSS.log

What the Test Does:
  1. DNS resolution check
  2. TCP connectivity test (port 990)
  3. SSL/TLS handshake verification
  4. FTP authentication test
  5. Directory listing (data channel test)
  6. File upload test
  7. Connection persistence test

The test will show detailed debug output including:
  • PASV responses (to verify correct IP)
  • Data channel connection attempts
  • SSL certificate details
  • Error messages and diagnostics

For more information, see:
  FTPS-Load-Balancing-Troubleshooting.md

Created: $(date)
EOF

chown "${TEST_USERNAME}:${TEST_USERNAME}" "${TEST_USER_HOME}/README.txt"
chmod 644 "${TEST_USER_HOME}/README.txt"

echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  Setup Complete!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"
echo ""
echo "Test user created successfully!"
echo ""
echo -e "${BOLD}Login Information:${NC}"
echo "  Username: ${TEST_USERNAME}"
echo "  Password: ${RANDOM_PASS:-<existing password>}"
echo ""
echo -e "${BOLD}How to use:${NC}"
echo "  1. Have your teammate log in as this user:"
echo "     ssh ${TEST_USERNAME}@$(hostname)"
echo ""
echo "  2. The FTPS test will run automatically on login"
echo ""
echo "  3. Test results will be displayed on screen and saved to:"
echo "     /tmp/ftps-test-results/ftps-test-*.log"
echo ""
echo -e "${BOLD}Manual test execution:${NC}"
echo "  ${TEST_USERNAME}@host:~$ ftps-test"
echo ""
echo -e "${BOLD}View test logs:${NC}"
echo "  ${TEST_USERNAME}@host:~$ ftps-logs"
echo "  ${TEST_USERNAME}@host:~$ ftps-latest"
echo ""
echo -e "${YELLOW}Note: The FTPS password is stored in the test script.${NC}"
echo -e "${YELLOW}File location: ${TEST_USER_HOME}/ftps-auto-test.sh${NC}"
echo ""

# Offer to set up SSH key
echo -e "${BOLD}Optional: Set up SSH key authentication?${NC}"
read -p "Do you want to add an SSH public key for passwordless login? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Paste the SSH public key (usually from ~/.ssh/id_rsa.pub):"
    read -r SSH_KEY

    if [ -n "$SSH_KEY" ]; then
        mkdir -p "${TEST_USER_HOME}/.ssh"
        echo "$SSH_KEY" >> "${TEST_USER_HOME}/.ssh/authorized_keys"
        chown -R "${TEST_USERNAME}:${TEST_USERNAME}" "${TEST_USER_HOME}/.ssh"
        chmod 700 "${TEST_USER_HOME}/.ssh"
        chmod 600 "${TEST_USER_HOME}/.ssh/authorized_keys"
        echo -e "${GREEN}✓ SSH key added${NC}"
        echo ""
        echo "Your teammate can now log in with:"
        echo "  ssh ${TEST_USERNAME}@$(hostname)"
    fi
fi

echo ""
echo "Setup complete!"
