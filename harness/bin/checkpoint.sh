#!/usr/bin/env bash
# Runs the checkpoint for a phase and records pass/fail in harness/state.json.
# Usage: harness/bin/checkpoint.sh <phase-id>
# Each phase's checks live in harness/phases/<id>.sh and must exit 0 to pass.
set -u
REPO="$(cd "$(dirname "$0")/../.." && pwd)"; H="$REPO/harness"; P="${1:?phase id}"
S="$H/phases/$P.sh"; [ -f "$S" ] || { echo "no checkpoint script for phase $P"; exit 2; }
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; OUT="$H/phases/$P.last.log"
if bash "$S" > "$OUT" 2>&1; then RES=pass; else RES=fail; fi
python3 - "$H/state.json" "$P" "$RES" "$NOW" <<'PY'
import json,sys
p,pid,res,now=sys.argv[1:5]; s=json.load(open(p))
for ph in s["phases"]:
    if str(ph["id"])==pid: ph["status"]=res; ph["checkpoint"]=f"{res} {now}"
s["updated"]=now; json.dump(s,open(p,"w"),indent=2); open(p,"a").write("\n")
PY
echo "phase $P: $RES (log: $OUT)"; [ "$RES" = pass ]
