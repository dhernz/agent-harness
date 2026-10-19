#!/usr/bin/env bash
# Checkpoint 0: Foundation. Example. Replace the checks with your project's own.
# One line per check; each must be a command that exits 0 when the thing is true.
source "$(dirname "$0")/lib.sh"; cd "$REPO"
check 0.1 "dependencies install"        pnpm install --frozen-lockfile
check 0.2 "typecheck and unit tests"    bash -c "pnpm typecheck && pnpm test"
check 0.3 "heartbeat runs"              bash -c "bash harness/bin/heartbeat.sh && test -s harness/STATUS.md"
# check 0.4 "staging api healthy"       curl -fsS -m 15 "$STAGING_API_URL/healthz"
finish
