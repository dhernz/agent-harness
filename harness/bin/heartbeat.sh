#!/usr/bin/env bash
# Heartbeat for the agent harness. Run every few minutes by heartbeat-loop.sh. Safe to run by hand.
# Recreates dead agent windows, nudges idle agents that still own unfinished phases,
# backs off on rate limits, and regenerates STATUS.md.
set -u
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
H="$REPO/harness"; source "$H/config.sh"
LOG="$H/heartbeat.log"; RT="$H/runtime"; mkdir -p "$RT"
export CMUX_QUIET=1
cmx() { timeout 20 "$CMUX" "$@"; }   # cmux can hang; never let one call stall the tick
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
log() { echo "$NOW $*" >> "$LOG"; }

WS_LIST="$(cmx list-workspaces 2>/dev/null)"
# If cmux does not answer or the pm workspace is missing, skip. Never recreate windows from a partial list.
if ! echo "$WS_LIST" | grep -qE 'workspace:[0-9]+ +pm( |$)'; then log "cmux unavailable or pm missing, tick skipped"; exit 0; fi
# Dedupe: keep the lowest ref per name, close the rest (a resumed session must run once).
echo "$WS_LIST" | awk '{ref=""; for(i=1;i<=NF;i++) if($i ~ /^workspace:[0-9]+$/) ref=$i; name=$NF; if(name=="[selected]") name=$(NF-1); if(ref!="") print ref, name}' \
  | sort -t: -k2 -n | awk '{ if (seen[$2]++) print $1 }' \
  | while read -r dup; do cmx close-workspace --workspace "$dup" >/dev/null 2>&1 && log "closed duplicate $dup"; done
WS_LIST="$(cmx list-workspaces 2>/dev/null)"

json() { python3 -c "import json,sys; d=json.load(open('$1')); print(d.get('$2') or '')"; }
setjson() { python3 - "$1" "$2" "$3" <<'PY'
import json,sys
p,k,v=sys.argv[1:4]; d=json.load(open(p)); d[k]=(None if v=="null" else v); json.dump(d,open(p,'w'),indent=2); open(p,'a').write("\n")
PY
}

agent_has_work() { # $1 = agent -> exit 0 if state.json has an unfinished phase it owns (and it is not on standby)
  python3 - "$H/state.json" "$1" "$H/agents/$1.json" <<'PY'
import json,sys
s=json.load(open(sys.argv[1])); a=sys.argv[2]
try:
    if json.load(open(sys.argv[3])).get("standby"): sys.exit(1)   # PM put this agent on standby: never auto-resume
except Exception: pass
if a=="pm": open_phases=[p for p in s["phases"] if p["status"]!="pass"]
else: open_phases=[p for p in s["phases"] if a in p["owner"].split(",") and p["status"] in ("in_progress","fail")]
sys.exit(0 if open_phases else 1)
PY
}

workspace_ref() { # $1 = workspace name -> prints ref or empty
  echo "$WS_LIST" | awk -v n="$1" '{ ref=""; for (i=1;i<=NF;i++) if ($i ~ /^workspace:[0-9]+$/) ref=$i; if (ref != "" && ($NF == n || $(NF-1) == n)) { print ref; exit } }'
}

for f in "$H"/agents/*.json; do
  name="$(json "$f" name)"; model="$(json "$f" model)"; sid="$(json "$f" session_id)"
  [ -z "$name" ] && continue
  rt="$RT/$name.json"; [ -f "$rt" ] || echo '{"last_heartbeat":null,"wait_until":null}' > "$rt"
  wait_until="$(json "$rt" wait_until)"
  if [ -n "$wait_until" ] && [ "$wait_until" \> "$NOW" ]; then log "$name waiting for rate limit reset until $wait_until"; continue; fi
  if ! agent_has_work "$name"; then setjson "$rt" last_heartbeat "$NOW"; continue; fi
  ref="$(workspace_ref "$name")"
  if [ -z "$ref" ]; then   # window is gone: reopen it, resuming the recorded session when there is one
    cmd="claude --model $model"; [ -n "$sid" ] && cmd="$cmd --resume $sid"
    wt="$WORKTREES/$name"; [ "$name" = pm ] && wt="$REPO"
    cmx new-workspace --name "$name" --cwd "$wt" --command "$cmd" --focus false >/dev/null 2>&1 && log "$name window recreated ($cmd)" || log "$name window recreate FAILED"
    setjson "$rt" last_heartbeat "$NOW"; continue
  fi
  screen="$(cmx read-screen --workspace "$ref" --lines 40 2>/dev/null || true)"
  if echo "$screen" | grep -qiE "usage limit|rate limit|limit reached|resets at|try again (at|in)"; then
    until_ts="$(date -u -v+"$RATE_LIMIT_WAIT" +%Y-%m-%dT%H:%M:%SZ)"
    setjson "$rt" wait_until "$until_ts"; log "$name rate limited, waiting until $until_ts"; continue
  fi
  setjson "$rt" wait_until null
  # Idle = a prompt line is on screen and nothing is running ("esc to interrupt" shows only while working).
  if echo "$screen" | grep -qE '^\s*[>❯]' && ! echo "$screen" | grep -qiE 'esc to interrupt|Esc to cancel|Enter to confirm'; then
    extra=""
    if [ "$name" = pm ]; then
      prs="$(cd "$REPO" && gh pr list --state open --json number,title --jq '.[] | "#\(.number) \(.title)"' 2>/dev/null | tr '\n' ';')"
      [ -n "$prs" ] && extra=" Open PRs waiting for you: $prs"
    fi
    # Never clear typed text: it may be the owner's instruction. Submit it first, then send the resume prompt.
    cmx send-key --workspace "$ref" Enter >/dev/null 2>&1; sleep 2
    cmx send --workspace "$ref" "Heartbeat: read harness/state.json and harness/agents/$name.json and continue your current phase. Commit before any long operation.$extra" >/dev/null 2>&1
    sleep 1; cmx send-key --workspace "$ref" Enter >/dev/null 2>&1 || true; sleep 2; cmx send-key --workspace "$ref" Enter >/dev/null 2>&1 || true   # Enter sometimes does not register the first time
    log "$name idle with open phase, resume prompt sent$extra"
  fi
  setjson "$rt" last_heartbeat "$NOW"
done

# STATUS.md
python3 - "$H" "$NOW" "$OWNER_NAME" <<'PY'
import json,sys,glob
H,now,owner=sys.argv[1:4]; s=json.load(open(f"{H}/state.json"))
lines=[f"# {s['project']} status\n\nLast heartbeat: {now}\n\n## Phases\n","| # | Phase | Owner | Status | Checkpoint |","|---|---|---|---|---|"]
for p in s["phases"]: lines.append(f"| {p['id']} | {p['name']} | {p['owner']} | {p['status']} | {p.get('checkpoint') or ''} |")
lines+=["\n## Agents\n","| Agent | Model | Phase | Last heartbeat | Waiting until |","|---|---|---|---|---|"]
for f in sorted(glob.glob(f"{H}/agents/*.json")):
    a=json.load(open(f)); r={}
    try: r=json.load(open(f"{H}/runtime/{a['name']}.json"))
    except Exception: pass
    lines.append(f"| {a['name']} | {a['model']} | {a.get('phase') or ''} | {r.get('last_heartbeat') or ''} | {r.get('wait_until') or ''} |")
n=sum(1 for l in open(f"{H}/QUESTIONS.md") if l.startswith("| 20"))
lines.append(f"\n## Questions for {owner}\n\n{n} open in harness/QUESTIONS.md\n")
open(f"{H}/STATUS.md","w").write("\n".join(lines))
PY
log "status regenerated"
