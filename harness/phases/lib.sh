# Shared helpers for harness/phases/<n>.sh. Sourced, never executed.
#
# House rules for a checkpoint script:
#  - Run every check, then exit non-zero if any failed. Tell the owner everything
#    that is wrong in one pass, not just the first thing.
#  - A check that cannot run because something is not built yet is a FAIL that
#    names the missing artefact and its owner. Never a skip, never a pass.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FAILED=0
begin()   { printf '[%s] %-58s ' "$1" "$2"; }
ok()      { printf 'pass%s\n' "${1:+  ($1)}"; }
bad()     { printf 'FAIL\n        %s\n' "$1"; FAILED=1; }
missing() { printf 'FAIL  (not built yet)\n        missing: %s\n        owner:   %s\n' "$1" "$2"; FAILED=1; }
# check <id> <label> <command...>: pass if the command exits 0, else show the tail of its output.
check() { local id="$1" label="$2"; shift 2; begin "$id" "$label"; local out
  if out="$("$@" 2>&1)"; then ok; else bad "$(printf '%s\n' "$out" | tail -8)"; fi; }
finish()  { [ "$FAILED" = 0 ] && echo "checkpoint passed" || { echo "checkpoint FAILED"; exit 1; }; }
