#!/usr/bin/env bash
# Opens one cmux workspace per build agent with its opening prompt.
# Creates the agent's git worktree (branch <agent>/work from origin/$BASE_BRANCH) if missing.
# Usage: harness/bin/launch-agents.sh [agent ...]   (default: every agent in harness/agents except pm)
set -u
REPO="$(cd "$(dirname "$0")/../.." && pwd)"; H="$REPO/harness"; source "$H/config.sh"; export CMUX_QUIET=1
AGENTS=("$@")
if [ ${#AGENTS[@]} -eq 0 ]; then
  for f in "$H"/agents/*.json; do n="$(basename "$f" .json)"; [ "$n" = pm ] || AGENTS+=("$n"); done
fi
git -C "$REPO" fetch -q origin "$BASE_BRANCH"
for a in "${AGENTS[@]}"; do
  [ -f "$H/agents/$a.json" ] || { echo "$a: no harness/agents/$a.json, skipping"; continue; }
  if "$CMUX" list-workspaces 2>/dev/null | awk '{print $NF}' | grep -qx "$a"; then echo "$a: workspace exists, skipping"; continue; fi
  model="$(python3 -c "import json;print(json.load(open('$H/agents/$a.json'))['model'])")"
  prompt="You are the $a agent. Read CLAUDE.md, then docs/product.md (the goal and what done means), docs/rules.md and docs/briefs/$a.md. Write docs/plans/$a.md as your brief asks, record your session in harness/agents/$a.json (set phase to 1), commit it on your branch and open a PR to $BASE_BRANCH. Then stop and wait for the PM review before building. Questions for $OWNER_NAME go to harness/QUESTIONS.md with your assumed answer."
  WT="$WORKTREES/$a"; mkdir -p "$WORKTREES"
  [ -d "$WT" ] || git -C "$REPO" worktree add -q "$WT" -b "$a/work" "origin/$BASE_BRANCH"
  "$CMUX" new-workspace --name "$a" --cwd "$WT" --command "claude --model $model \"$prompt\"" --focus false >/dev/null 2>&1 && echo "$a: launched ($model)" || echo "$a: launch FAILED"
done
