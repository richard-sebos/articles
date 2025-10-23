## Log Aggregation in a Post-Perimeter World

Unlike traditional enterprise systems where logs are streamed in real-time to a central SIEM, secure laptops operating in zero-trust or disconnected environments require a different model.

### Design Principles:
- Local log capture with `journalctl`, `auditd`, firewall logs
- Tamper-evident chaining (hash + timestamp)
- GPG signing of manifest sets
- Opportunistic or manual export (USB, rsync, cloud vault)
- Local detection with minimal trust assumptions

This model supports forensics, integrity assurance, and audit compliance — without assuming persistent connectivity.
