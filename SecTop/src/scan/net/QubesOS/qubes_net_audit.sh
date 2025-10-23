#!/bin/bash
# qubes_net_audit.sh — Qubes Containment Audit Orchestrator (v2)
# Requires modules in ./lib
# Usage:
#   ./qubes_net_audit.sh [--json out.json] [--nmap] [--nmap-vm sys-net]

set -o pipefail
BASE_DIR="$(dirname "$(realpath "$0")")"
LIB_DIR="$BASE_DIR/lib"

# --- Load modular libraries ---
source "$LIB_DIR/util.sh"
source "$LIB_DIR/get_vm_list.sh"
source "$LIB_DIR/get_vm_ips.sh"
source "$LIB_DIR/run_nmap_scan.sh"
source "$LIB_DIR/collect_logs.sh"

# --- Parse arguments ---
JSON_OUT=""
DO_NMAP=0
NMAP_VM="sys-net"
NMAP_PORTS="${NMAP_PORTS:--F}"
NMAP_EXTRA="${NMAP_EXTRA:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --json) shift; JSON_OUT="$1" ;;
    --nmap) DO_NMAP=1 ;;
    --nmap-vm) shift; NMAP_VM="$1" ;;
    -h|--help)
      echo "Usage: $0 [--json out.json] [--nmap] [--nmap-vm sys-net]"
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
  shift
done

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "🔍 Qubes Network Audit started @ $timestamp"
echo "Scanning mode: $( [ "$DO_NMAP" -eq 1 ] && echo 'with nmap' || echo 'IP listing only')"
echo

# --- Enumerate VMs ---
vm_list=$(get_vm_list)
if [ -z "$vm_list" ]; then
  echo "No running VMs found." >&2
  exit 1
fi

declare -A vm_ips
declare -A vm_raw
declare -A vm_nmap
declare -A vm_logs

# --- Collect IP data ---
for vm in $vm_list; do
  echo "==> $vm"
  read -r ip_info raw <<<"$(get_vm_ips "$vm")"
  vm_ips["$vm"]="$ip_info"
  vm_raw["$vm"]="$raw"

  if [ -z "$ip_info" ]; then
    echo "   (no IPv4 data)"
  else
    IFS=',' read -ra pairs <<< "$ip_info"
    for p in "${pairs[@]}"; do
      [ -z "$p" ] && continue
      iface=$(cut -d'|' -f1 <<<"$p")
      ip=$(cut -d'|' -f2 <<<"$p")
      cidr=$(cut -d'|' -f3 <<<"$p")
      echo "   Interface: $iface"
      echo "   IP:        $ip"
      echo "   CIDR:      /$cidr"
      echo
    done
  fi
done

# --- Optional nmap scan ---
if [ "$DO_NMAP" -eq 1 ]; then
  echo "🔎 Launching nmap scans from $NMAP_VM..."
  for vm in $vm_list; do
    if [ -z "${vm_ips[$vm]}" ]; then
      vm_nmap["$vm"]=""
      continue
    fi
    scan_result=$(run_nmap_scan "$NMAP_VM" "${vm_ips[$vm]}" "$NMAP_PORTS" "$NMAP_EXTRA")
    vm_nmap["$vm"]="$scan_result"
  done
fi

# --- Collect logs ---
echo
echo "🧾 Gathering firewall and system logs..."
for vm in $vm_list; do
  logs=$(collect_logs "$vm" "$timestamp")
  vm_logs["$vm"]="$logs"
done

# --- Build JSON manifest ---
if [ -n "$JSON_OUT" ]; then
  echo
  echo "💾 Writing JSON manifest -> $JSON_OUT"
  build_json "$timestamp" "$vm_list" vm_ips vm_nmap vm_logs > "$JSON_OUT"
  echo "✅ Manifest saved: $JSON_OUT"

  # --- Tamper-evident ProofTrail entry ---
  manifest_hash=$(sha256sum "$JSON_OUT" | awk '{print $1}')
  echo "$timestamp $manifest_hash $JSON_OUT" >> "$BASE_DIR/prooftrail.log"
  sha256sum "$BASE_DIR/prooftrail.log" > "$BASE_DIR/prooftrail.log.sha256"
  echo "🔐 ProofTrail updated and hashed."
fi

echo
echo "✅ Qubes Containment Audit complete."
echo "Audit timestamp: $timestamp"
