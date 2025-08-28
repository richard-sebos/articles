#!/bin/bash
#
# SSH App Session Control Script
# Location: /etc/profile.d/ssh_app_session.sh
# Purpose: If user is in ssh_app group and SSH session is detected, run secure app and exit.

# Only run for interactive login sessions
[[ $- != *i* ]] && return

# Check if user is in 'ssh_app' group
if id -nG "$USER" | grep -qw "ssh_app"; then
    # Check if it's an SSH session
    if [[ -n "$SSH_CONNECTION" ]]; then
        logger -t ssh_app_session "$USER SSH login at $(date) from $SSH_CLIENT"
        exec /usr/local/bin/ssh_secure_test.sh
        exit 0
    fi
fi
