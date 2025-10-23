#!/bin/bash
# run_nmap_scan <scanner_vm> <ip_list_csv> <ports> <extra_flags>
run_nmap_scan() {
  local scan_vm="$1"
  local ip_list="$2"
  local ports="$3"
  local extras="$4"
  local all_output=""
  IFS=',' read -ra pairs <<<"$ip_list"
  for p in "${pairs[@]}"; do
    [ -z "$p" ] && continue
    ip=$(cut -d'|' -f2 <<<"$p")
    echo "   Scanning $ip..."
    local nmap_cmd="nmap -sT -Pn $ports $extras $ip"
    local result
    result=$(qvm-run --pass-io "$scan_vm" "$nmap_cmd 2>/dev/null || true" 2>/dev/null)
    all_output+=$'\n'"--- $ip ---"$'\n'"$result"$'\n'
    local open_ports
    open_ports=$(grep -E "^[0-9]+/tcp" <<<"$result" | awk '{print $1" "$3}' | paste -sd "; " -)
    if [ -n "$open_ports" ]; then
      echo "     open: $open_ports"
    else
      echo "     (no common TCP ports open)"
    fi
  done
  printf "%s" "$all_output"
}

