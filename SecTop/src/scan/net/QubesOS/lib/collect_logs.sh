#!/bin/bash
# collect_logs <vmname> <timestamp>
# Collects relevant logs (firewall, qrexec, kernel) from a VM if accessible.
# Output: raw log text printed to stdout (may be empty).

collect_logs() {
  local vm="$1"
  local ts="$2"      # ISO timestamp string
  local out=""
  local log_window="--since '$ts'"

  # Only attempt on system VMs (firewall, net, whonix)
  case "$vm" in
    sys-* )
      echo "   🔎 Collecting logs from $vm ..."
      # Try firewall or kernel drops
      out+="$(qvm-run --pass-io "$vm" "sudo journalctl -k -n 200 2>/dev/null | grep -E 'DROP|REJECT' || true" 2>/dev/null)"
      out+=$'\n'"$(qvm-run --pass-io "$vm" "sudo journalctl -u qubes-firewall -n 200 2>/dev/null || true" 2>/dev/null)"
      ;;
    * )
      # For AppVMs, capture any qrexec/syslog events after the test timestamp
      out+="$(qvm-run --pass-io "$vm" "sudo journalctl -t qrexec -n 50 2>/dev/null || true" 2>/dev/null)"
      ;;
  esac

  printf "%s" "$out"
}

