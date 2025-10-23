#!/bin/bash
# get_vm_ips <vmname>
# Output: "iface|ip|cidr,iface|ip|cidr,... raw_output"

get_vm_ips() {
  local vm="$1"
  local out ip_info=""
  out=$(qvm-run --pass-io "$vm" "ip -4 -o addr show scope global 2>/dev/null" 2>/dev/null)
  if [ -z "$out" ]; then
    echo ""
    return 0
  fi

  while read -r line; do
    iface=$(awk '{print $2}' <<<"$line")
    ip_cidr=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+' <<<"$line")
    ip=$(cut -d'/' -f1 <<<"$ip_cidr")
    cidr=$(cut -d'/' -f2 <<<"$ip_cidr")
    ip_info+="$iface|$ip|$cidr,"
  done <<< "$out"

  echo "$ip_info $out"
}

