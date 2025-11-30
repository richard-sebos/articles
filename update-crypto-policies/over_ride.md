cat > /usr/local/bin/lftp-legacy << 'EOF'
#!/bin/bash
export CRYPTO_POLICY=LEGACY
exec /usr/bin/lftp "$@"
EOF
