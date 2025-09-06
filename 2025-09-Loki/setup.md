```bash
sudo LOKI_HOST=192.168.35.35 bash install-promtail-agent.sh

# Look for that line coming from the remote's journal
curl -sG 'http://192.168.35.35:3100/loki/api/v1/query' \
  --data-urlencode 'query={job="journal"} |= "promtail_probe_"' \
  --data-urlencode 'limit=5' | jq -r '.data.result[].values[][1]'

HOST="jump.sebostech.local"   # replace with the actual hostname
START=$(date -u -d '15 minutes ago' +%s%N)
END=$(date -u +%s%N)

# journal logs from that host
curl -sG 'http://127.0.0.1:3100/loki/api/v1/query_range' \
  --data-urlencode "query={job=\"journal\",host=\"$HOST\"}" \
  --data-urlencode "start=$START" --data-urlencode "end=$END" \
  --data-urlencode 'limit=100' | jq -r '.data.result[].values[][1]' | head

# if that host is sending via syslog (6514) instead of a local agent:
curl -sG 'http://127.0.0.1:3100/loki/api/v1/query_range' \
  --data-urlencode "query={job=\"syslog\",host=\"$HOST\"}" \
  --data-urlencode "start=$START" --data-urlencode "end=$END" \
  --data-urlencode 'limit=100' | jq -r '.data.result[].values[][1]' | head
```
