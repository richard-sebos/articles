#!/usr/bin/env bash

# === CONFIGURATION ===
HOST="barrie"
USER="youruser"
TOTAL_CONNECTIONS=40000
JOBS=400
PAYLOAD_FILE="payload_10k.txt"
RESULT_DIR="results"

# === PREP ===
mkdir -p "$RESULT_DIR"
: > "$RESULT_DIR/summary.csv"

# Generate 10KB test file if it doesn't exist
if [ ! -f "$PAYLOAD_FILE" ]; then
  head -c 1024 /dev/urandom > "$PAYLOAD_FILE"
fi

# === WORKER FUNCTION ===
simulate_user() {
  local id="$1"
  local start
  local end
  local latency

  start=$(date +%s%3N)

  scp -q -o BatchMode=yes -o ConnectTimeout=5 "$PAYLOAD_FILE" "$HOST:/tmp/payload_${id}.txt" 2>/dev/null

  end=$(date +%s%3N)
  latency=$((end - start))

  echo "$id,$latency" > "$RESULT_DIR/latency_${id}.log"
}

export -f simulate_user
export HOST USER PAYLOAD_FILE RESULT_DIR

# === PARALLEL EXECUTION ===
#seq 1 "$TOTAL_CONNECTIONS" | parallel -j"$JOBS" simulate_user
#seq 1 "$TOTAL_CONNECTIONS" | xargs -P100 -n1 simulate_user
#seq 1 "$TOTAL_CONNECTIONS" | xargs -n1 -P"$JOBS" -I{} bash -c 'simulate_user "$@"' _ {}
seq 1 "$TOTAL_CONNECTIONS" | xargs -P"$JOBS" -I{} bash -c 'simulate_user "$@"' _ {}

# === AGGREGATE ===
(
  echo "session_id,latency_ms"
  for f in "$RESULT_DIR"/latency_*.log; do
    cat "$f"
  done | sort -t',' -k1 -n
) > "$RESULT_DIR"/summary.csv

# === STATS ===
awk -F',' 'NR > 1 {sum += $2; count++; if(min=="" || $2 < min) min=$2; if($2 > max) max=$2}
END {
  print "Connections:", count
  print "Average:", sum/count, "ms"
  print "Min:", min, "ms"
  print "Max:", max, "ms"
}' "$RESULT_DIR"/summary.csv

