# Getting Started with Your Second Brain

A knowledge system built on Claude Code that remembers what you've learned, tracks your projects, and gets smarter the more you use it. No more re-explaining context every conversation.

This guide uses the **Claude desktop app**, so you don't need a terminal for day-to-day use. Work through Part 1 once (~30 min). Use Part 2 as your daily reference. Part 3 is only for when something goes wrong.

Prefer the terminal? Everything here works the same in the Claude Code CLI; see [Using the terminal instead](#using-the-terminal-instead).

---

## Part 1 — One-Time Setup (~30 min)

### 1. What you need

- **A Claude account on a Pro, Max, Team Premium or Enterprise plan.** The Free plan does not include Claude Code.
- **The Claude desktop app** for Windows or macOS, signed in. The download link is in the [desktop quickstart](https://code.claude.com/docs/en/desktop-quickstart).
- **Git.** The second brain saves its progress with Git, and its automatic reminders and session close-out run as small bash scripts.
  - **Windows:** install **Git for Windows**, which also provides bash (step 2).
  - **macOS:** Git is usually already there. If not, typing `git --version` in Terminal offers to install it.

### 2. Install and configure Git (Windows)

Download Git for Windows from https://git-scm.com/download/win and run the installer with its default options. Or, in PowerShell:

```powershell
winget install Git.Git
```

If you're on a work computer and `winget` needs admin rights you don't have, ask IT to install Git for you.

Then tell Git who you are. Open **Git Bash** (on Windows) or **Terminal** (on macOS):

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Windows only, to prevent line-ending warnings:

```bash
git config --global core.autocrlf false
```

**If the desktop app was open while you installed Git, restart it.**

### 3. Get the second brain onto your computer

**Option A — clone it (recommended).** In Git Bash or Terminal:

```bash
cd ~/Documents
git clone https://github.com/DomTSM718/second-brain-template.git second-brain
cd second-brain
git remote remove origin
```

The last line disconnects your copy from the template, so the copy is entirely yours and nothing you write is sent anywhere.

**Option B — download a ZIP.** On the [repository page](https://github.com/DomTSM718/second-brain-template), click **Code → Download ZIP**. Unzip it into your Documents folder and rename the folder to `second-brain`. You'll turn it into a Git repository in step 6.

### 4. Open it in Claude Code

1. Open the desktop app and click the **Code** tab.
2. Choose the **Local** environment.
3. Click **Select folder** and choose your `second-brain` folder.
4. Set the permission mode to **Manual** or **Accept edits** while you're learning. You'll see what Claude wants to do before it does it.

**Always open this same folder.** That's how Claude finds `CLAUDE.md` and loads the system.

### 5. Fill in your profile

`CLAUDE.md` has a **User Profile** section that tells Claude who you are and how you like to work. Rather than editing it by hand, let Claude interview you. Type:

> Help me fill in the User Profile section of CLAUDE.md. Ask me one question at a time, then write my answers into the file.

It will cover your role and context, the kinds of work you do, how you like answers (detailed, or just the answer; whether to push back when you're wrong), what takes too long today, your tools, and what success looks like in six months.

The more honest and specific you are, the better Claude's help will fit you. Read the result before you accept the change.

### 6. Save a first checkpoint

If you used **Option B (ZIP)**, first type:

> Initialise this folder as a Git repository.

Then, either way:

> Commit my changes with the message "My second brain setup".

Want a backup? Create a **private** repository on your own GitHub account and ask Claude to push your second brain to it.

### 7. Allow the tools you use (optional)

`.claude/settings.json` lists the commands Claude may run without asking you each time. Anything not on the list still works; Claude just asks first. To add some, ask Claude, for example:

> Add python, pip and pytest to the allowed commands in .claude/settings.json.

| Stack | Entries for `"allow"` |
|---|---|
| Python | `"Bash(python *:*)"`, `"Bash(pip *:*)"`, `"Bash(pytest *:*)"` |
| JavaScript | `"Bash(npm *:*)"`, `"Bash(node *:*)"`, `"Bash(npx *:*)"` |
| TypeScript | `"Bash(npm *:*)"`, `"Bash(node *:*)"`, `"Bash(npx *:*)"`, `"Bash(tsc *:*)"` |
| C# / .NET | `"Bash(dotnet *:*)"`, `"Bash(nuget *:*)"` |
| Go | `"Bash(go *:*)"`, `"Bash(make *:*)"` |
| Rust | `"Bash(cargo *:*)"`, `"Bash(rustc *:*)"` |

The same file also carries a **deny** list that blocks destructive commands. Leave that part alone.

### 8. Create your first project

Pick something real you're actually working on, not a placeholder:

```
/new-project my-project-name
```

Then ask Claude to help fill it in:

> Help me fill in the context for my-project-name, and add two or three real tasks.

### 9. Test that it works

Run these one at a time. Each should do something obvious:

```
/overview
```
→ Shows the tasks you just added.

```
/switch my-project-name
```
→ Loads your project's context, tasks and patterns.

```
/add-task Draft the first report
```
→ Adds a new task.

```
/idea What if we automated the monthly summary?
```
→ Captures and categorises the idea.

Then ask Claude a real question about your project. The answer should show it knows what's in `CLAUDE.md` and your project's `context.md`.

Commit again, and you're set up. Move to Part 2.

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

Just talk to Claude normally. Ask it to analyse data, write code, explain things, draft documents, whatever you need. The second brain gives Claude context about your projects and patterns, so its answers get sharper over time.

**Switching focus:**

```
/switch other-project
```

Claude loads everything about that project, with no re-explaining.

**Got an idea?**

```
/idea Build a dashboard for tracking monthly metrics
```

It gets categorized and stored. Come back to it later.

**End of session:**

```
/learn
```

Claude asks you a few questions about what you did, then saves the patterns. **This is the single most important habit.** Skip everything else before you skip this; it's how the brain grows.

### For bigger tasks (>15 minutes)

Don't just dive in. Ask Claude to plan it:

```
/plan Build the monthly reporting workbook
```

Claude breaks the task into steps of about 10 minutes each. Then run:

```
/step
```

Each `/step` does one piece, commits the progress to Git, and previews what's next. If you get interrupted or hit a usage limit, you pick up exactly where you left off.

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

- **Just use it.** Don't overthink the system; it builds itself as you work.
- **Run `/learn` before closing.** It's the most valuable habit.
- **Context beats cleverness.** The more you tell Claude about your project in `context.md`, the better the output.
- **Capture ideas cheaply.** Use `/idea` liberally. You can triage later.
- **Don't memorize commands.** Type `/` and browse what's available.
- **Always open the `second-brain` folder.** That's how Claude finds `CLAUDE.md`.

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
| No **Code** tab, or you're asked to upgrade | Claude Code needs a Pro plan or higher. |
| Commands like `/overview` don't do anything | The wrong folder is selected. Start a new session, click **Select folder** and choose `second-brain`. |
| Errors mentioning `bash` (Windows) | Git for Windows isn't installed, or the app was open during the install. Install it, then restart the desktop app. |
| `/overview` shows nothing | You haven't added any tasks yet. Run `/add-task`, or edit `projects/[name]/tasks.md`. |
| Claude doesn't know about my project | Run `/switch project-name` first so it loads the context. |
| Plan got interrupted halfway through | Open the folder again, run `/plan-status` to see where you left off, then `/step` to continue. |
| Git line-ending warnings (Windows) | `git config --global core.autocrlf false` |

If nothing here matches, ask Claude: *"I'm seeing [problem]. What might be wrong with the Second Brain setup?"* It has the full docs loaded and can usually diagnose its own system.

### Using the terminal instead

Install the Claude Code CLI using the official instructions at https://code.claude.com/docs/en/setup (on Windows, in PowerShell: `irm https://claude.ai/install.ps1 | iex`). Then run `claude` from inside the `second-brain` folder. The steps and commands in this guide are otherwise the same.

---

## Setup checklist

Use this for a quick recap of Part 1:

- [ ] Pro plan or higher
- [ ] Claude desktop app installed and signed in
- [ ] Git installed and configured (Git for Windows on Windows)
- [ ] Second brain cloned, or downloaded and unzipped
- [ ] Folder opened from the **Code** tab (Local, **Select folder**)
- [ ] `CLAUDE.md` User Profile filled in
- [ ] First checkpoint committed
- [ ] First project created with real tasks
- [ ] `/overview`, `/switch` and `/learn` all working
