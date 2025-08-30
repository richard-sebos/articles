#!/bin/bash
# Launch the app safely with input/output control

# Reset dangerous environment variables
unset BASH_ENV ENV SHELL

# Trap CTRL+C, CTRL+Z, etc.
trap '' INT QUIT TSTP
# Replace the shell with the app
exec /opt/test_app/app_entrypoint.py

# If app exits, close the session instead of dropping to shell
echo "[ERROR] App terminated. Disconnecting."
sleep 2
exit 1
