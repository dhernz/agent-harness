#!/usr/bin/env bash
# Runs the heartbeat on a timer inside a cmux workspace named "heartbeat".
# (Not launchd: macOS blocks launchd jobs from reading ~/Documents.)
# Also keeps the Mac awake while it runs: a sleep cuts every agent mid-response.
# caffeinate cannot stop a lid close; keep the lid open or use an external display.
cd "$(dirname "$0")/../.." || exit 1
source harness/config.sh
if ! pgrep -f "caffeinate -i -s -w $$" >/dev/null 2>&1; then caffeinate -i -s -w $$ & fi
while true; do date -u +"%Y-%m-%dT%H:%M:%SZ heartbeat tick"; bash harness/bin/heartbeat.sh; sleep "$HEARTBEAT_SECONDS"; done
