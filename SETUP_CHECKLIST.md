# Second Brain Setup Checklist

A one-page recap. Each step is explained in full in **[GETTING_STARTED.md](GETTING_STARTED.md)**.

---

## What's Included

```
second-brain/
├── CLAUDE.md                 # System instructions (CUSTOMIZE the User Profile)
├── GETTING_STARTED.md        # Setup and daily use - start here
├── README.md                 # Overview
├── ONBOARDING.md             # Deeper walkthrough of the system
├── INSTALLATION_GUIDE.md     # Terminal (CLI) route, for those who prefer it
├── .claude/
│   ├── commands/             # Slash commands
│   ├── skills/               # Workflows
│   ├── agents/               # Specialized agents
│   ├── hooks/                # Reminder and session-close scripts
│   └── settings.json         # Permissions, safety and hook wiring
├── memory/                   # Empty knowledge storage
├── projects/                 # Project templates
└── brain-health/             # Metrics tracking
```

---

## Setup Steps

### 1. Prerequisites
- [ ] Claude **Pro plan or higher** (Free does not include Claude Code)
- [ ] **Claude desktop app** installed and signed in
- [ ] **Git** installed (on Windows: Git for Windows, which also provides bash for the hooks)
- [ ] Git configured with your name and email

### 2. Get the repository
- [ ] Cloned (`git clone https://github.com/DomTSM718/second-brain-template.git second-brain`, then `git remote remove origin`)
- [ ] ...or downloaded via **Code → Download ZIP** and unzipped to a folder named `second-brain`

### 3. Open it
- [ ] Desktop app → **Code** tab → **Local** → **Select folder** → `second-brain`
- [ ] Permission mode set to **Manual** or **Accept edits** while learning

### 4. Make it yours
- [ ] `CLAUDE.md` User Profile filled in (ask Claude to interview you, one question at a time)
- [ ] First checkpoint committed (ZIP users: ask Claude to initialise a Git repository first)

### 5. Allow your tools (optional)
- [ ] Commands you use often added to `"allow"` in `.claude/settings.json`

### 6. First project
- [ ] `/new-project my-project` run, with real context and two or three real tasks

### 7. Test it
- [ ] `/overview` shows your tasks
- [ ] `/switch my-project` loads your project
- [ ] `/learn` runs at the end of a session

---

## Customization Summary

| File | Required? | What to Do |
|------|-----------|------------|
| `CLAUDE.md` | **Yes** | Fill in User Profile |
| `projects/[name]/*` | **Yes** | Create your first project |
| `.claude/settings.json` | Optional | Allow the tools you use |
| `memory/semantic/tech/*` | Recommended | Document your tools and decisions |

---

## Next Steps

1. Run `/overview` each morning
2. Run `/learn` after completing work
3. Check `/grow` weekly for brain health
4. Read `ONBOARDING.md` when you want to understand the system in depth

**You're ready to start using your Second Brain!**
