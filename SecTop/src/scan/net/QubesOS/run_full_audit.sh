#!/bin/bash
# run_full_audit.sh — One-touch Qubes Containment Audit Runner (v2)
# Executes full audit (nmap + logs), generates reports, and updates ProofTrail

set -euo pipefail
BASE_DIR="$(dirname "$(realpath "$0")")"
AUDIT_SCRIPT="$BASE_DIR/qubes_net_audit.sh"
OUT_DIR="$BASE_DIR/audit_runs"
mkdir -p "$OUT_DIR"

timestamp=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
run_dir="$OUT_DIR/run_${timestamp}"
mkdir -p "$run_dir"

outfile="$run_dir/audit_${timestamp}.json"
reportfile="$run_dir/report_${timestamp}.txt"
historyfile="$run_dir/history_${timestamp}.txt"

echo "🧱 Starting Qubes Containment Audit @ $timestamp"
echo "Run directory: $run_dir"
echo

# --- Step 0: configure scan parameters ---
export NMAP_PORTS="-p 22,80,443"
export NMAP_EXTRA="-sV --open"

# --- Step 1: run audit ---
echo "🚀 Running full containment audit..."
"$AUDIT_SCRIPT" --nmap --json "$outfile"

# --- Step 2: verify ProofTrail integrity ---
if [ -f "$BASE_DIR/prooftrail.log.sha256" ]; then
  echo
  echo "🔐 Verifying ProofTrail integrity..."
  if sha256sum -c "$BASE_DIR/prooftrail.log.sha256"; then
    echo "✅ ProofTrail verified."
  else
    echo "❌ ProofTrail verification failed!" >&2
  fi
fi

# --- Step 3: generate human-readable report ---
if command -v python3 &>/dev/null && [ -f "$BASE_DIR/generate_qubes_report.py" ]; then
  echo
  echo "🧾 Generating audit report..."
  python3 "$BASE_DIR/generate_qubes_report.py" "$outfile" "$reportfile"
  echo "✅ Report saved to: $reportfile"
else
  echo
  echo "⚠️  Skipping report generation (Python script not found)"
fi

# --- Step 4: summarize ProofTrail history ---
if command -v python3 &>/dev/null && [ -f "$BASE_DIR/report_audit_history.py" ]; then
  echo
  echo "📜 Building ProofTrail history summary..."
  python3 "$BASE_DIR/report_audit_history.py" | tee "$historyfile"
  echo "✅ History summary saved to: $historyfile"
else
  echo
  echo "⚠️  Skipping ProofTrail history summary (script not found)"
fi

# --- Step 5: tail report preview ---
echo
echo "📊 Report tail (last 10 lines):"
tail -n 10 "$reportfile" || tail -n 10 "$outfile"
echo
echo "✅ Full containment audit completed successfully @ $timestamp"
echo "Artifacts created:"
echo "   JSON Manifest : $outfile"
echo "   Human Report  : $reportfile"
echo "   History Report: $historyfile"
echo "   ProofTrail Log: $BASE_DIR/prooftrail.log"
