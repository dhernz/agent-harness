# Machine-specific settings for the harness scripts. Every script sources this file.
# Change these for your machine. Nothing else in harness/bin should need editing.

# Where agent worktrees live (one folder per agent). Must be OUTSIDE the repo.
WORKTREES="${WORKTREES:-$HOME/Code/worktrees}"

# The branch every agent cuts from and opens PRs into.
BASE_BRANCH="${BASE_BRANCH:-staging}"

# cmux CLI (the terminal app that hosts one workspace per agent).
CMUX="${CMUX_BIN:-/Applications/cmux.app/Contents/Resources/bin/cmux}"

# How often the heartbeat runs, and how long to back off after a rate limit.
HEARTBEAT_SECONDS="${HEARTBEAT_SECONDS:-300}"
RATE_LIMIT_WAIT="${RATE_LIMIT_WAIT:-1H}"   # BSD date -v+ syntax: 1H, 30M

# Your name, as agents address you in QUESTIONS.md and STATUS.md.
OWNER_NAME="${OWNER_NAME:-the user}"
