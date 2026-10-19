# Agent harness

This lets you run a small AI software team on your project. One AI acts as the
**project manager (PM)**. It plans the work, hands it to AI **engineers**
(backend, frontend, testing, or whatever your project needs), reviews what they
build and merges it. A small background script keeps everyone working: it
reopens an engineer that crashed and nudges one that stopped too early.

You don't set any of this up by hand. You install one app, clone this repo, and
start your agent. The agent tells you what else to install, asks you about your
project, then configures everything and launches the team.

---

## Who does what

| | You (the user) | Your agent (the PM) |
|---|---|---|
| Setup | Install Claude Code, clone this repo, download the apps the agent asks for, answer its questions about your project | Checks what's installed, configures every setup file, creates the branches and tests, writes each engineer's brief |
| Running | Check the status page, answer questions, give direction | Launches the engineers, starts the background script, reviews and merges their work every 10 minutes |
| Decisions | Yours: what to build, which services and accounts to use, what's off limits | Asks you, writes the answers down, and makes sure the engineers follow them |

---

## For the user

### 1. Install Claude Code

[Install Claude Code](https://docs.anthropic.com/en/docs/claude-code/setup) and
sign in. Your Claude plan needs access to **Fable 5.1** (for the PM) and
**Opus 5** (for the engineers).

You need a Mac. Your agent will walk you through installing the rest, but here
are the links in case you want them:

| App | What it's for | Link |
|---|---|---|
| cmux | A terminal that gives each agent its own tab, so you can watch the whole team | [cmux.com](https://cmux.com/docs/getting-started) (download the app and drag it into Applications) |
| GitHub CLI | Lets the agents open and merge pull requests on your GitHub | [cli.github.com](https://cli.github.com) |
| Homebrew | Installs the other tools; your agent uses it if you have it | [brew.sh](https://brew.sh) |

### 2. Clone this repo and start your agent

Open the Terminal app and run:

```bash
git clone https://github.com/altananetwork/agent-harness.git
cd agent-harness
claude --model claude-fable-5-1
```

Then paste this:

> You are the PM agent. Read harness/PM-SETUP.md and follow it from step 0.
> Tell me anything I need to download or sign in to, and ask me about my
> project before you configure anything.

### 3. Do what the agent asks

It will:
- **ask you to download apps** it can't install on its own (usually cmux), and
  to sign in to GitHub. Do it, then tell the agent you're done.
- **ask about your project.** Have these ready:
  - **what the product is:** a paragraph, and the main things a user does with it.
  - **your project's GitHub repo:** an existing one, or ask the agent to create one.
  - **the team you want:** for example backend, frontend and testing. If you're not sure, the agent will suggest one.
  - **decisions you've already made:** where it's hosted, which database, how users sign in, which AI models, and anything that's off limits. Each decision you give is one the engineers won't keep asking about.
  - **where your passwords and API keys are:** a private file on your machine. It never goes into the repo.
  - **designs, if you have them:** mockups, a Figma link, or screenshots.
- **show you a summary** of the team and plan, and wait for your yes.
- **move itself into cmux.** It opens a cmux tab named `pm` and carries on
  there. From then on, talk to the PM in that tab. A tab opens for each
  engineer and one for the background script.

Keep the Mac awake while the team works: in System Settings → Battery, stop it
from sleeping, and keep the lid open. A sleeping Mac stops every agent mid-sentence.

### 4. Day to day

- **See where things are:** ask the PM "what's the status?", or open `harness/STATUS.md`.
- **Answer questions:** the engineers don't stop to wait for you. They write
  questions in `harness/QUESTIONS.md`, along with the answer they're assuming,
  and keep going. Answer in the last column, or tell the PM.
- **Change direction:** say it to the PM. Don't give orders to an engineer
  directly unless the PM asks you to.
- **Pause everything:** tell the PM "pause the team". To resume, say "resume".

---

## For the PM agent

Everything you need is in **[`harness/PM-SETUP.md`](harness/PM-SETUP.md)**:
the prerequisites to check, what to configure, how to launch the engineers and
the heartbeat, and the loop you run. The user should not need to open that file.
