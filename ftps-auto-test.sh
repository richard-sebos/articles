#!/bin/bash
################################################################################
# FTPS Auto-Test Script
# Purpose: Automatically test FTPS connection through VIP with detailed debug
# Usage: This script runs automatically when the test user logs in
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration - EDIT THESE VALUES
FTPS_HOST="your-ftps-fqdn.example.com"
FTPS_USER="your-ftps-username"
FTPS_PASS="your-ftps-password"
TEST_DIR="/tmp/ftps-test-results"
LOG_FILE="${TEST_DIR}/ftps-test-$(date +%Y%m%d-%H%M%S).log"

################################################################################
# Functions
################################################################################

print_header() {
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC}     ${BOLD}FTPS Load Balancer Diagnostic Test Suite${NC}              ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_test() {
    echo -e "${YELLOW}▶${NC} ${BOLD}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_prerequisites() {
    local missing_tools=()

    if ! command -v lftp &> /dev/null; then
        missing_tools+=("lftp")
    fi

    if ! command -v openssl &> /dev/null; then
        missing_tools+=("openssl")
    fi

    if ! command -v nc &> /dev/null && ! command -v netcat &> /dev/null; then
        missing_tools+=("netcat")
    fi

    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo ""
        echo "To install on Fedora/RHEL:"
        echo "  sudo dnf install lftp openssl netcat"
        echo ""
        echo "To install on Debian/Ubuntu:"
        echo "  sudo apt-get install lftp openssl netcat"
        return 1
    fi

    return 0
}

test_dns_resolution() {
    print_test "Test 1: DNS Resolution"

    local resolved_ip
    resolved_ip=$(host "$FTPS_HOST" 2>/dev/null | grep "has address" | awk '{print $4}' | head -n1)

    if [ -z "$resolved_ip" ]; then
        print_error "Failed to resolve $FTPS_HOST"
        return 1
    else
        print_success "Resolved $FTPS_HOST to $resolved_ip"
        echo "  VIP Address: $resolved_ip"

        # Store for later use
        echo "$resolved_ip" > "${TEST_DIR}/vip-address.txt"
        return 0
    fi
}

test_tcp_connectivity() {
    print_test "Test 2: TCP Connectivity to Port 990"

    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/${FTPS_HOST}/990" 2>/dev/null; then
        print_success "TCP connection to ${FTPS_HOST}:990 successful"
        return 0
    else
        print_error "Cannot establish TCP connection to ${FTPS_HOST}:990"
        print_info "Possible causes:"
        echo "  • Firewall blocking port 990"
        echo "  • Load balancer not forwarding port 990"
        echo "  • IIS FTP service not running"
        return 1
    fi
}

test_ssl_handshake() {
    print_test "Test 3: SSL/TLS Handshake"

    local ssl_output
    ssl_output=$(timeout 10 openssl s_client -connect "${FTPS_HOST}:990" -showcerts </dev/null 2>&1)
    local ssl_result=$?

    if [ $ssl_result -eq 0 ]; then
        print_success "SSL/TLS handshake successful"

        # Extract certificate details
        local cert_subject
        cert_subject=$(echo "$ssl_output" | openssl x509 -noout -subject 2>/dev/null | sed 's/subject=//')

        local cert_issuer
        cert_issuer=$(echo "$ssl_output" | openssl x509 -noout -issuer 2>/dev/null | sed 's/issuer=//')

        local cert_dates
        cert_dates=$(echo "$ssl_output" | openssl x509 -noout -dates 2>/dev/null)

        echo "  Subject: $cert_subject"
        echo "  Issuer: $cert_issuer"
        echo "  $cert_dates"

        # Check for certificate warnings
        if echo "$ssl_output" | grep -q "Verify return code: 0"; then
            print_success "Certificate verification: PASSED"
        else
            print_warning "Certificate verification: FAILED"
            local verify_error
            verify_error=$(echo "$ssl_output" | grep "Verify return code:" | head -n1)
            echo "  $verify_error"
        fi

        return 0
    else
        print_error "SSL/TLS handshake failed"
        echo ""
        echo "SSL Error Output:"
        echo "$ssl_output" | tail -n 20
        return 1
    fi
}

test_ftp_basic_connection() {
    print_test "Test 4: Basic FTP Connection and Authentication"

    local ftp_test
    ftp_test=$(lftp -u "${FTPS_USER},${FTPS_PASS}" \
        -e "set ftp:ssl-allow yes; set ftp:ssl-protect-data yes; set ssl:verify-certificate no; set net:timeout 15; open ftps://${FTPS_HOST}; echo 'Connection successful'; bye" \
        2>&1)
    local result=$?

    if [ $result -eq 0 ] && echo "$ftp_test" | grep -q "Connection successful"; then
        print_success "FTP authentication successful"
        return 0
    else
        print_error "FTP authentication failed"
        echo ""
        echo "Error Output:"
        echo "$ftp_test"
        return 1
    fi
}

test_ftp_directory_listing() {
    print_test "Test 5: Directory Listing (Tests PASV Data Channel)"

    echo ""
    echo "This test will show if the data channel can be established."
    echo "Look for the PASV response and data connection attempts."
    echo ""
    echo "--- BEGIN DEBUG OUTPUT ---"

    local ls_output
    ls_output=$(lftp -u "${FTPS_USER},${FTPS_PASS}" \
        -e "set ftp:ssl-allow yes; set ftp:ssl-protect-data yes; set ssl:verify-certificate no; set net:timeout 30; debug 3; open ftps://${FTPS_HOST}; ls; bye" \
        2>&1)
    local result=$?

    echo "$ls_output"
    echo "--- END DEBUG OUTPUT ---"
    echo ""

    if [ $result -eq 0 ]; then
        print_success "Directory listing successful"

        # Try to extract PASV information
        local pasv_line
        pasv_line=$(echo "$ls_output" | grep -i "227 Entering Passive Mode" | head -n1)

        if [ -n "$pasv_line" ]; then
            echo ""
            print_info "PASV Response Found:"
            echo "  $pasv_line"

            # Try to decode PASV response
            local pasv_data
            pasv_data=$(echo "$pasv_line" | grep -oP '\(\K[^)]+' | head -n1)

            if [ -n "$pasv_data" ]; then
                IFS=',' read -ra ADDR <<< "$pasv_data"
                local pasv_ip="${ADDR[0]}.${ADDR[1]}.${ADDR[2]}.${ADDR[3]}"
                local pasv_port=$((${ADDR[4]} * 256 + ${ADDR[5]}))

                echo "  Decoded IP: $pasv_ip"
                echo "  Decoded Port: $pasv_port"

                # Compare with VIP
                if [ -f "${TEST_DIR}/vip-address.txt" ]; then
                    local vip_address
                    vip_address=$(cat "${TEST_DIR}/vip-address.txt")

                    if [ "$pasv_ip" = "$vip_address" ]; then
                        print_success "PASV IP matches VIP - Configuration is CORRECT!"
                    else
                        print_error "PASV IP does NOT match VIP - Configuration issue detected!"
                        echo "  Expected (VIP): $vip_address"
                        echo "  Received (PASV): $pasv_ip"
                        echo ""
                        print_warning "This indicates IIS FTP Firewall Support is not configured correctly"
                        echo "  The backend IIS server is advertising its own IP instead of the VIP"
                    fi
                fi
            fi
        fi

        return 0
    else
        print_error "Directory listing failed"

        # Analyze the failure
        if echo "$ls_output" | grep -qi "timeout\|timed out"; then
            echo ""
            print_warning "Timeout detected - likely data channel issue"
            echo "  Possible causes:"
            echo "  • PASV response contains backend IP instead of VIP"
            echo "  • Passive port range not forwarded through load balancer"
            echo "  • Firewall blocking passive ports (50000-50099)"
            echo "  • Session persistence not configured on load balancer"
        fi

        if echo "$ls_output" | grep -qi "connection refused"; then
            echo ""
            print_warning "Connection refused - likely routing issue"
            echo "  Possible causes:"
            echo "  • Client trying to connect to backend IP directly"
            echo "  • Backend IP not routable from client network"
        fi

        return 1
    fi
}

test_ftp_file_transfer() {
    print_test "Test 6: File Upload Test"

    # Create a test file
    local test_file="${TEST_DIR}/test-upload-$(date +%s).txt"
    echo "FTPS Test File - $(date)" > "$test_file"
    echo "This file was uploaded to test FTPS connectivity" >> "$test_file"

    local upload_output
    upload_output=$(lftp -u "${FTPS_USER},${FTPS_PASS}" \
        -e "set ftp:ssl-allow yes; set ftp:ssl-protect-data yes; set ssl:verify-certificate no; set net:timeout 30; debug 3; open ftps://${FTPS_HOST}; put ${test_file}; bye" \
        2>&1)
    local result=$?

    if [ $result -eq 0 ]; then
        print_success "File upload successful"
        echo "  Uploaded: $(basename "$test_file")"
        return 0
    else
        print_error "File upload failed"
        echo ""
        echo "Upload Error Output:"
        echo "$upload_output" | tail -n 30
        return 1
    fi
}

test_connection_persistence() {
    print_test "Test 7: Connection Persistence (Multiple Operations)"

    local persistence_output
    persistence_output=$(lftp -u "${FTPS_USER},${FTPS_PASS}" \
        -e "set ftp:ssl-allow yes; set ftp:ssl-protect-data yes; set ssl:verify-certificate no; set net:timeout 30; open ftps://${FTPS_HOST}; ls; pwd; ls; bye" \
        2>&1)
    local result=$?

    if [ $result -eq 0 ]; then
        print_success "Multiple operations successful - session persistence working"
        return 0
    else
        print_error "Multiple operations failed"
        print_warning "This may indicate session persistence issues on the load balancer"
        return 1
    fi
}

generate_summary() {
    print_section "Test Summary and Recommendations"

    local passed=0
    local failed=0

    # Count results (this is simplified - in reality you'd track each test)
    if [ -f "${TEST_DIR}/test-results.tmp" ]; then
        passed=$(grep -c "PASS" "${TEST_DIR}/test-results.tmp" 2>/dev/null || echo 0)
        failed=$(grep -c "FAIL" "${TEST_DIR}/test-results.tmp" 2>/dev/null || echo 0)
    fi

    echo -e "${BOLD}Test Results:${NC}"
    echo -e "  ${GREEN}Passed: $passed${NC}"
    echo -e "  ${RED}Failed: $failed${NC}"
    echo ""

    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✓ All tests passed!${NC}"
        echo ""
        echo "The FTPS load balancer configuration appears to be working correctly."
        echo "Both control and data channels are functioning properly."
    else
        echo -e "${RED}${BOLD}✗ Some tests failed${NC}"
        echo ""
        echo -e "${BOLD}Recommended Actions:${NC}"
        echo ""
        echo "1. Check IIS FTP Firewall Support Configuration:"
        echo "   • Verify 'External IP Address' is set to VIP: $(cat "${TEST_DIR}/vip-address.txt" 2>/dev/null || echo 'unknown')"
        echo "   • Verify 'Data Channel Port Range' is set to 50000-50099"
        echo "   • Restart FTP service: net stop ftpsvc && net start ftpsvc"
        echo ""
        echo "2. Check Load Balancer Configuration:"
        echo "   • Verify port 990 is forwarded to backend servers"
        echo "   • Verify ports 50000-50099 are forwarded to backend servers"
        echo "   • Verify source IP persistence is enabled (30+ minute timeout)"
        echo ""
        echo "3. Check Firewall Rules:"
        echo "   • Verify port 990 is allowed from clients to VIP"
        echo "   • Verify ports 50000-50099 are allowed from clients to VIP"
        echo ""
        echo "4. Review the detailed logs above for specific error messages"
    fi

    echo ""
    echo -e "${BOLD}Documentation:${NC}"
    echo "  See FTPS-Load-Balancing-Troubleshooting.md for complete setup guide"
    echo ""
    echo -e "${BOLD}Log File:${NC}"
    echo "  $LOG_FILE"
    echo ""
}

cleanup() {
    # Clean up temporary files
    rm -f "${TEST_DIR}/test-results.tmp"
}

################################################################################
# Main Execution
################################################################################

main() {
    # Create test directory
    mkdir -p "$TEST_DIR"

    # Redirect all output to both console and log file
    exec > >(tee -a "$LOG_FILE")
    exec 2>&1

    # Start testing
    print_header

    echo "Test started: $(date)"
    echo "Testing host: $FTPS_HOST"
    echo "Log file: $LOG_FILE"
    echo ""

    # Check prerequisites
    print_section "Checking Prerequisites"
    if ! check_prerequisites; then
        echo ""
        print_error "Cannot proceed without required tools"
        exit 1
    fi
    print_success "All required tools are installed"

    # Initialize results tracking
    > "${TEST_DIR}/test-results.tmp"

    # Run tests
    print_section "Running Diagnostic Tests"

    test_dns_resolution && echo "PASS" >> "${TEST_DIR}/test-results.tmp" || echo "FAIL" >> "${TEST_DIR}/test-results.tmp"
    echo ""

    test_tcp_connectivity && echo "PASS" >> "${TEST_DIR}/test-results.tmp" || echo "FAIL" >> "${TEST_DIR}/test-results.tmp"
    echo ""

    test_ssl_handshake && echo "PASS" >> "${TEST_DIR}/test-results.tmp" || echo "FAIL" >> "${TEST_DIR}/test-results.tmp"
    echo ""

    test_ftp_basic_connection && echo "PASS" >> "${TEST_DIR}/test-results.tmp" || echo "FAIL" >> "${TEST_DIR}/test-results.tmp"
    echo ""

    test_ftp_directory_listing && echo "PASS" >> "${TEST_DIR}/test-results.tmp" || echo "FAIL" >> "${TEST_DIR}/test-results.tmp"
    echo ""

    test_ftp_file_transfer && echo "PASS" >> "${TEST_DIR}/test-results.tmp" || echo "FAIL" >> "${TEST_DIR}/test-results.tmp"
    echo ""

    test_connection_persistence && echo "PASS" >> "${TEST_DIR}/test-results.tmp" || echo "FAIL" >> "${TEST_DIR}/test-results.tmp"
    echo ""

    # Generate summary
    generate_summary

    # Cleanup
    cleanup

    echo ""
    echo "Test completed: $(date)"
    echo ""
    echo -e "${BOLD}Press Enter to continue or Ctrl+C to exit${NC}"
    read -r
}

# Run main function
main
