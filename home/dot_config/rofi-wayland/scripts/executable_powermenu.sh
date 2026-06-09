#!/usr/bin/env bash
set -uo pipefail
# Power menu — managed by chezmoi
# Launches wlogout for lock/logout/suspend/hibernate/reboot/shutdown

if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
    exit 0
fi

wlogout
