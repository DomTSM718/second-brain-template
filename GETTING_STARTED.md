# Getting Started with Your Second Brain

A knowledge system built on top of Claude Code that remembers what you've learned, tracks your projects, and gets smarter the more you use it. No more re-explaining context every conversation.

This guide is self-contained. Work through Part 1 once (~30 min). Use Part 2 as your daily reference. Part 3 is only for when something goes wrong.

---

## Part 1 — One-Time Setup (~30 min)

### 1. Confirm prerequisites

You need:
- **A Claude account** with a Pro or Max subscription (Claude Code requires it)
- **Node.js v18 or newer**
- **Git 2.x or newer**
- A terminal you're comfortable using

### 2. Check what's already installed

Open a terminal and run:

```bash
node --version    # need v18+
npm --version     # comes with Node
git --version     # need 2.x+
```

Skip the next step for anything that already works.

### 3. Install what's missing

**Node.js:**
- Windows: `winget install OpenJS.NodeJS.LTS` or download from https://nodejs.org (LTS)
- macOS: `brew install node@20` or download from https://nodejs.org
- Linux: `sudo apt install nodejs npm`

**Git:**
- Windows: `winget install Git.Git` or download from https://git-scm.com
- macOS: `xcode-select --install`
- Linux: `sudo apt install git`

If you're on a corporate Windows machine and `winget` requires admin rights you don't have, ask IT to install Node.js LTS and Git for you — both are standard developer tools.

### 4. Configure Git

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

Windows only — prevents line-ending warnings:

```bash
git config --global core.autocrlf false
```

### 5. Install the Claude Code CLI

```bash
npm install -g @anthropic-ai/claude-code
```

Verify:

```bash
claude --version
```

If `claude: command not found` after installing, close and reopen your terminal. If it still fails, see Part 3.

### 6. Get the Second Brain repository

Clone it into a folder you'll remember:

```bash
cd ~/Documents          # or wherever you want it
git clone https://github.com/DomTSM718/second-brain-template.git second-brain
cd second-brain
```

From now on, **always run Claude Code from inside the `second-brain` folder.** That's how it finds `CLAUDE.md` and loads the system.

### 7. Authenticate Claude Code

```bash
claude
```

This opens a browser window. Log in with your Claude account and authorize. Once authenticated, type `/exit` to quit — you'll come back in a moment.

### 8. Customize CLAUDE.md

Open `CLAUDE.md` in your editor. Find the **User Profile** section and fill it in for yourself. The more honest and specific you are, the better Claude can help you.

```bash
code CLAUDE.md          # or whatever editor you use
```

Answer these for yourself:

**Role & Context:**
- What's your job title?
- What size company?
- What do you mainly work on day-to-day?
- How long have you been using Claude or other AI tools?

**Work Domains:**
- What languages and frameworks do you use most?
- What other kinds of work do you do? (data analysis, writing, research, planning, etc.)

**Communication Style:**
- Do you want detailed explanations or just the answer?
- Do you want Claude to push back when it thinks you're wrong?

**Pain Points:**
- What takes too long right now?
- What context do you keep having to re-explain?
- What's frustrating about your current workflow?

**Tech Stack:**
- IDE, primary language, framework, database, OS

**Goals (6 months):**
- What does success look like in 6 months with this system?

**Code Standards:**
- Whatever conventions you follow for your language

Save the file when done.

### 9. Configure permissions for your stack

Open `settings.local.json`. The `allow` list controls which shell commands Claude can run without asking each time. Add entries based on your stack.

```bash
code settings.local.json
```

Add entries after the existing `"Bash(grep:*)"` line. Don't forget commas between entries.

| Stack | Add to "allow" |
|---|---|
| Python | `"Bash(python *:*)"`, `"Bash(pip *:*)"`, `"Bash(pytest *:*)"` |
| JavaScript | `"Bash(npm *:*)"`, `"Bash(node *:*)"`, `"Bash(npx *:*)"` |
| TypeScript | `"Bash(npm *:*)"`, `"Bash(node *:*)"`, `"Bash(npx *:*)"`, `"Bash(tsc *:*)"` |
| C# / .NET | `"Bash(dotnet *:*)"`, `"Bash(nuget *:*)"` |
| Go | `"Bash(go *:*)"`, `"Bash(make *:*)"` |
| Rust | `"Bash(cargo *:*)"`, `"Bash(rustc *:*)"` |
| Docker | `"Bash(docker *:*)"`, `"Bash(docker-compose *:*)"` |

Anything not on the list will still work — Claude will just ask before running it.

### 10. Create your first project

Pick something real you're actually working on. Don't use a placeholder.

```bash
mkdir -p projects/my-project-name
cp projects/_template/* projects/my-project-name/
```

Open `projects/my-project-name/context.md` and fill in:

- Project name and what kind of project it is
- Tech stack
- What you're currently working on
- Any architectural decisions already made

Open `projects/my-project-name/tasks.md` and add 2–3 tasks you actually need to do. Real tasks, not test data — this makes the next step feel real.

Open `projects/INDEX.md` and add your project to the table.

### 11. Test that it works

Start Claude Code from inside `second-brain`:

```bash
claude
```

Run these one at a time. Each should do something obvious:

```
/overview
```
→ Should show the tasks you just added.

```
/switch my-project-name
```
→ Should load your project's context, tasks, and patterns.

```
/add-task Write tests for the login endpoint
```
→ Should add a new task.

```
/idea What if we cached the API responses?
```
→ Should capture and categorize the idea.

Then ask Claude an actual question about your project. It should answer with awareness of what you put in `CLAUDE.md` and `context.md`.

If anything fails, see Part 3.

### 12. Commit your customizations

```bash
git add .
git commit -m "Customized Second Brain setup"
```

If you want your own backup, create a private repo on GitHub and:

```bash
git remote set-url origin https://github.com/YOUR_USERNAME/second-brain.git
git push -u origin main
```

You're set up. Move to Part 2.

---

## Part 2 — Daily Use (your ongoing reference)

### The five commands you'll actually use

| Command | What it does | When to use it |
|---|---|---|
| `/overview` | Shows urgent tasks across all your projects | Every morning |
| `/switch [project]` | Loads a project's full context instantly | When changing focus |
| `/idea [text]` | Captures an idea with auto-categorization | Whenever inspiration strikes |
| `/learn` | Extracts patterns from work you just completed | End of every session |
| `/grow` | Shows your brain's health and growth metrics | Weekly check-in |

### Daily workflow

**Morning:**

```
/overview
```

See what's urgent. Pick your first task.

**During work:**

Just talk to Claude normally. Ask it to write code, explain things, debug issues — whatever you need. The Second Brain gives Claude context about your projects and patterns, so its answers get sharper over time.

**Switching focus:**

```
/switch other-project
```

Claude instantly loads everything about that project — no re-explaining.

**Got an idea?**

```
/idea Build a dashboard for tracking warehouse metrics
```

It gets categorized and stored. Come back to it later.

**End of session:**

```
/learn
```

Claude asks you a few questions about what you did, then saves the patterns. **This is the single most important habit.** Skip everything else before you skip this — it's how the brain grows.

### For bigger tasks (>15 minutes)

Don't just dive in. Ask Claude to plan it:

```
/plan Build user authentication for the app
```

Claude breaks the task into steps of about 10 minutes each. Then run:

```
/step
```

Each `/step` executes one piece, commits the progress to git, and previews what's next. If you get interrupted or hit a rate limit, you pick up exactly where you left off.

Check progress anytime:

```
/plan-status
```

### Setting up additional projects

When you start something new:

```
/new-project project-name
```

This scaffolds the standard structure (`context.md`, `tasks.md`, `patterns.md`). Fill in `context.md` first. The more context you give, the better Claude helps you.

### Tips that actually matter

- **Just use it.** Don't overthink the system — it builds itself as you work.
- **Run `/learn` before closing.** Most valuable habit. Treat it like brushing your teeth.
- **Context beats cleverness.** The more you tell Claude about your project in `context.md`, the better the output.
- **Capture ideas cheaply.** Use `/idea` liberally. You can triage later.
- **Don't memorize commands.** Type `/` and browse what's available.
- **Always start Claude Code from the `second-brain` folder.** That's how it finds `CLAUDE.md`.

### What to expect over time

- **Week 1:** You're using basic commands and getting comfortable.
- **Week 2:** Your projects have real context. Claude's answers get noticeably better.
- **Week 4:** Patterns start compounding. Claude remembers how you like things done.
- **Month 2+:** Switching between projects feels instant. No more copy-pasting context.

### Need a deeper answer?

Ask Claude itself. It has the full system documentation loaded:

> *"How does /learn work in the Second Brain?"*
> *"What's the difference between semantic and episodic memory?"*
> *"Show me what's in my patterns file for project X."*

---

## Part 3 — Troubleshooting

| Problem | Fix |
|---|---|
| `claude: command not found` | Close and reopen your terminal. Still broken? Check that `npm config get prefix` is in your `PATH`. |
| Authentication fails | Run `claude logout`, then `claude` again. |
| Commands like `/overview` don't work | You're not inside the `second-brain` folder. `cd` into it and re-launch. |
| Permission denied on `npm install -g` (macOS/Linux) | See `INSTALLATION_GUIDE.md` for setting up `~/.npm-global`. |
| Git line-ending warnings (Windows) | `git config --global core.autocrlf false` |
| `/overview` shows nothing | You haven't added any tasks yet. Edit `projects/[name]/tasks.md`. |
| Claude doesn't know about my project | Did you run `/switch project-name`? It needs to load the context first. |
| Plan got interrupted halfway through | Re-launch Claude, then `/plan-status` shows where you left off. Run `/step` to continue. |

If nothing here matches, ask Claude: *"I'm seeing [problem]. What might be wrong with the Second Brain setup?"* — it has the full docs loaded and can usually diagnose its own system.

---

## Setup checklist

Use this if you want a quick recap of Part 1:

- [ ] Node.js v18+ installed
- [ ] Git installed and configured
- [ ] Claude Code CLI installed
- [ ] Claude Code authenticated
- [ ] Repository cloned
- [ ] `CLAUDE.md` User Profile filled in
- [ ] `settings.local.json` permissions configured for your stack
- [ ] First project created with real tasks
- [ ] `/overview`, `/switch`, `/learn` all working
- [ ] Customizations committed to git
