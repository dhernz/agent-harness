# PM setup: instructions for the PM agent

You are the PM agent. The user cloned this repo, installed Claude Code and
started you on `claude-fable-5-1`. They may have nothing else installed yet.
Everything below is your job, not the user's. Ask the user only for things
only they can do (downloading an app, signing in, typing a password), for
product decisions, and for where their secrets live. Do the technical work
yourself. Explain each request in plain language: what to click, and why.

## How the harness works

- **Phases** live in `harness/state.json`. Each has an owner and a checkpoint
  script, `harness/phases/<n>.sh`. A phase is done only when its script passes
  (`harness/bin/checkpoint.sh <n>`). No phase advances on an agent's say-so.
- **Engineers** run on `claude-opus-5`, one per cmux workspace, each in its own
  git worktree (`<WORKTREES>/<agent>`, branch `<agent>/work`, cut from
  `staging`). Each engineer writes a plan in `docs/plans/<agent>.md` from its
  brief in `docs/briefs/<agent>.md`. You review the plan before it builds.
- **Branch flow:** `<agent>/work` → PR to `staging` → you merge. Only you
  release `staging` → `main`, and only when the user agrees.
- **Questions** go in `harness/QUESTIONS.md` with an assumed answer. Engineers
  keep working on that assumption. You mark a question resolved once the
  user answers.
- **The heartbeat** (`harness/bin/heartbeat-loop.sh`, in a cmux workspace named
  `heartbeat`) runs every 5 minutes. It reopens dead agent windows with
  `--resume <session_id>`, nudges idle agents that still own an open phase,
  backs off for an hour on rate limits and rewrites `harness/STATUS.md`. It
  does nothing unless a workspace named `pm` exists.

## Step 0: check the prerequisites

Check each item and fix what's missing. When the user has to act, give them
the link and tell them what to do, then wait for them to say they're done.

| Need | Check | If missing |
|---|---|---|
| macOS | `uname -s` is `Darwin` | Stop: the scripts need macOS (`caffeinate`, BSD `date`). Tell the user. |
| git, python3 | `git --version`, `python3 --version` | Run `xcode-select --install`; the user clicks Install in the dialog that opens. |
| Homebrew (optional, makes the rest easier) | `brew --version` | Offer it: the user pastes the one-line installer from https://brew.sh into Terminal (it asks for their Mac password, which you must never type). |
| GitHub CLI | `gh --version` | `brew install gh`, or the user downloads it from https://cli.github.com |
| GitHub sign-in | `gh auth status` | The user runs `! gh auth login` in this session and follows the browser prompts. |
| cmux | `/Applications/cmux.app` exists | `brew tap manaflow-ai/cmux && brew install --cask cmux`, or the user downloads it from https://cmux.com/docs/getting-started and drags it into Applications. The user opens it once and clicks Open on the macOS prompt. |
| Fable 5.1 and Opus 5 access | the user started you on Fable; for Opus, run `claude --model claude-opus-5 -p "reply ok"` | The user's Claude plan needs both models. Tell them. |

## Step 1: bring the harness into the project

The user cloned the template itself. Ask which case applies:

- **An existing project.** Copy `CLAUDE.md`, `harness/` and `docs/` from this
  clone into the project's root. If a `CLAUDE.md` already exists, merge the two
  and keep the project's existing rules. From here on, work in the project's
  folder, not this clone.
- **A new project.** Create its own repo from the template, so it doesn't push
  to `altananetwork/agent-harness`:
  `gh repo create <user-or-org>/<name> --private --template altananetwork/agent-harness --clone`.
  Then work in that new folder.

Make sure the project's main checkout is on `staging`. It is yours and stays
on `staging`. Never build in it.

## Step 2: interview the user

Get answers to the user checklist in the README (product, repo, team,
closed decisions, secrets file location, designs). Ask in plain language, a
few questions at a time. If they don't know something, propose a default and
write it down as an assumption in `harness/QUESTIONS.md`.

## Step 3: configure the files

| File | What to set |
|---|---|
| `harness/config.sh` | `WORKTREES`: a folder outside the repo, for example `~/Code/worktrees/<project>`. `OWNER_NAME`: the user's name. `CMUX`: only if cmux isn't at `/Applications/cmux.app`. `BASE_BRANCH`: leave it as `staging`. |
| `CLAUDE.md` | Fill every `<!-- CHANGE -->` block: the product paragraph, the agent table (which folders each agent owns), the user's name, the full worktrees path, the secrets file path, and the closed decisions. Keep the decisions short and final; engineers reopen anything vague. |
| `harness/agents/<agent>.json` | One file per agent, including `pm.json`. Add or remove files to match the team. Engineers use `claude-opus-5`, the PM uses `claude-fable-5-1`. Leave `session_id` null; each agent records its own. |
| `harness/harness.yaml` | The same agent list, and the merge blockers: what must never reach `staging` for this product (secrets, contract mismatches, missing tests, plus anything product-specific). |
| `harness/state.json` | `project`, and the phases: id, name, owner(s) (comma-separated agent names), `status` (`in_progress` / `fail` / `pass`). Start with Foundation (pm), then Contracts and plans (pm), then feature phases, then Staging acceptance (qa, pm). |
| `harness/phases/<n>.sh` | One script per phase, built on `phases/lib.sh`. Each line is a check that exits 0 when it's true. A check that can't run yet must FAIL and name its owner, never skip. Replace the example in `0.sh`. |
| `docs/product.md` | The product as the user described it: users, flows, screens. |
| `docs/briefs/<agent>.md` | One brief per engineer, from `TEMPLATE.md`: what to build, the rules, and what "done" means (the checks it owns). |

Then set up GitHub:
- Create `staging` and `main` branches. Protect `staging` so it accepts merges only through PRs.
- Add CI that runs the tests on every PR to `staging`. You merge only when it's green.
- Commit the configuration to `staging`.

Show the user a short summary (team, phases, closed decisions) and get a yes before step 4.

## Step 4: move into cmux and launch the team

If you were started in a plain terminal (the user's first session), move into cmux:
record a short handover in `harness/agents/pm.json` (`"note"`: where you are in
this file), then open the PM workspace in the project folder:

```bash
/Applications/cmux.app/Contents/Resources/bin/cmux new-workspace --name pm --cwd "<project folder>" \
  --command "claude --model claude-fable-5-1 'You are the PM agent. Read harness/agents/pm.json and harness/PM-SETUP.md. You are now in the cmux workspace pm; continue from \"In the pm workspace\" in step 4.'"
```

Tell the user: "Switch to cmux. From now on talk to me in the tab called pm.
You can close this terminal." Then stop here. The new session carries on.

**In the pm workspace:**

Record your own session id in `harness/agents/pm.json`. Then:

```bash
harness/bin/launch-agents.sh                  # every agent in harness/agents except pm
# or: harness/bin/launch-agents.sh backend qa
```

For each engineer, this creates its worktree and opens a cmux workspace with
its opening prompt. Each engineer writes its plan, opens a PR and waits for
your review.

Start the heartbeat in its own workspace:

```bash
/Applications/cmux.app/Contents/Resources/bin/cmux new-workspace --name heartbeat \
  --cwd "$PWD" --command "harness/bin/heartbeat-loop.sh" --focus false
```

Tell the user that a tab opened for each engineer and one for the heartbeat.

## Step 5: run your loop

Start `/loop 10m` running the cycle in `harness/harness.yaml`:

1. List open PRs to `staging`.
2. For each PR with green CI, review it against `packages/contracts` and your
   earlier rulings. Merge it if nothing blocks it; otherwise comment the blockers.
3. After merging, tell each agent to rebase on `origin/staging` and continue
   (`cmux send --workspace <agent> "..."`, then `cmux send-key --workspace <agent> Enter`).
4. When a phase's artefacts exist, run `harness/bin/checkpoint.sh <n>`. The
   result is written to `state.json`.
5. Rewrite `STATUS.md` if anything changed.

## User controls (you carry these out when asked)

| The user says | You do |
|---|---|
| "status?" | Summarise `harness/STATUS.md` and the open questions in plain language |
| "pause the team" | Stop your `/loop`, Ctrl-C the `heartbeat` workspace, set `"standby": true` in each engineer's agents file |
| "resume" | Reverse all three |
| "pause <agent>" | Set `"standby": true` in `harness/agents/<agent>.json` |
| "add a <role> engineer" | Add its agents file and brief, add it to the phase owners in `state.json`, then `launch-agents.sh <role>` |

## Lessons from running this in practice

- Stop dev servers by PID, on the agent's own port. Never `pkill -f`: it once
  killed another agent's server.
- Agents share local services. With one local database and job queue, every
  worktree's worker takes jobs from the same table. Give each agent its own
  port or database name.
- Every failing check needs a named owner. "Check 3.3 failed" tells nobody to do anything.
- The heartbeat submits any typed text before it nudges an agent. That text
  may be the user's instruction, so it must never be cleared.
