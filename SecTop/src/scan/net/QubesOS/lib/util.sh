#!/bin/bash
# util.sh — helpers for JSON output and ProofTrail integrity

json_escape() {
  # escape stdin to valid JSON string
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

# build_json <timestamp> <vm_list> <ips_ref> <nmap_ref> <logs_ref>
build_json() {
  local timestamp="$1"
  local vm_list="$2"
  local -n ips_ref="$3"
  local -n nmap_ref="$4"
  local -n logs_ref="$5"

  echo "{"
  echo "  \"generated_at\": \"$timestamp\","
  echo "  \"qubes\": ["
  local first=true
  for vm in $vm_list; do
    $first || echo "    ,"
    first=false
    echo "    {"
    echo "      \"name\": \"$vm\","
    echo "      \"interfaces\": ["
    local pairs="${ips_ref[$vm]}"
    if [ -n "$pairs" ]; then
      IFS=',' read -ra arr <<<"$pairs"
      local sep=""
      for p in "${arr[@]}"; do
        [ -z "$p" ] && continue
        iface=$(cut -d'|' -f1 <<<"$p")
        ip=$(cut -d'|' -f2 <<<"$p")
        cidr=$(cut -d'|' -f3 <<<"$p")
        echo "        $sep{ \"interface\": \"$iface\", \"ip\": \"$ip\", \"cidr\": \"$cidr\" }"
        sep=","
      done
    fi
    echo "      ],"

    # nmap output
    if [ -n "${nmap_ref[$vm]}" ]; then
      esc_nmap=$(printf "%s" "${nmap_ref[$vm]}" | json_escape)
      echo "      \"nmap_raw_output\": $esc_nmap,"
    else
      echo "      \"nmap_raw_output\": null,"
    fi

    # system logs
    if [ -n "${logs_ref[$vm]}" ]; then
      esc_logs=$(printf "%s" "${logs_ref[$vm]}" | json_escape)
      echo "      \"system_logs\": $esc_logs"
    else
      echo "      \"system_logs\": null"
    fi

    echo "    }"
  done
  echo "  ]"
  echo "}"
}
