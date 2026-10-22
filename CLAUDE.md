# <project name>

<!-- CHANGE: one paragraph on what the product is and how the repo is laid out. -->
<What the product does.> This repo is a monorepo: `apps/web`, `apps/api`,
`packages/...`.

## Who works here

<!-- CHANGE: one row per agent. Must match harness/agents/*.json and harness/harness.yaml. -->
| Agent | Model | Owns |
|---|---|---|
| PM | Fable 5.1 | harness, `packages/contracts`, phase gates, reviews and merges, releases |
| Backend | Opus 5 | `apps/api`, `packages/db`, `infra/` |
| Frontend | Opus 5 | `apps/web` |
| QA | Opus 5 | `packages/test-kit`, `.github/workflows`, checkpoint runs |

Model rule: only the PM runs on Fable. Every other agent, and every subagent
any agent spawns, runs on Opus 5 (`claude --model claude-opus-5`).

## How an agent starts and works

1. Read `harness/state.json`, `docs/product.md` (the goal and what "done"
   means), `docs/rules.md`, then your brief in `docs/briefs/<agent>.md`.
2. Write your plan in `docs/plans/<agent>.md`. The PM reviews it against
   `packages/contracts` before you build. Do not build before that review.
3. Record your session in `harness/agents/<agent>.json` (session id, phase).
4. Build only in the packages you own. Anything that crosses a package
   boundary goes through `packages/contracts` and a PM review.
5. Questions for <owner name> go in `harness/QUESTIONS.md` with the answer you
   are assuming. Pause only on a question that blocks you; otherwise keep going
   on the assumption and mark it.
6. Work ONLY in your own git worktree: `<WORKTREES>/<agent>` (branch
   `<agent>/work`, cut from `staging`). The main checkout is the PM's and stays
   on `staging`; never switch its branch. Rebase your worktree on
   `origin/staging` after every PM merge. Commit to your branch often, and
   always before a long operation. A killed session must lose nothing.
7. No phase advances until QA writes `pass` for it in `harness/state.json`.

## Branch flow (mandatory)

feature branch -> `staging` -> `main`. Branch off `staging`. Open PRs with
`gh pr create --base staging`. Never PR to `main`; `main` receives releases
from `staging` only, done by the PM.

## Tests (mandatory)

Tests ship with the code and run in CI. Unit tests in every package, contract
tests against `packages/contracts`, end to end tests in `packages/test-kit`.
Manual QA alone does not count.

## Secrets

Never in the repo. Load them with
`set -a; source <path to your .env file outside the repo>; set +a`. Never copy
values into files, logs, PRs or chat.

## Decisions that are closed (do not reopen; ask the PM if one seems wrong)

<!-- CHANGE: hosting, accounts, regions, database, auth, models, limits.
     Every decision you write here is one the agents stop re-asking. -->
- ...
