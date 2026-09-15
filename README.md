# Second Brain

Your AI-powered second brain that compounds knowledge across all your work.

## What This Is

A knowledge management system for Claude Code that:
- **Preserves context** across conversations (no more re-explaining)
- **Extracts patterns** from your work automatically
- **Compounds knowledge** - each task makes future tasks easier
- **Manages projects** with zero context-switching overhead

## Quick Start

**Full walkthrough: [GETTING_STARTED.md](GETTING_STARTED.md)** (about 30 minutes, no terminal needed day to day).

1. **You need** a Claude Pro plan or higher, the Claude desktop app, and Git (Git for Windows on Windows).
2. **Get this repository**: clone it, or use **Code → Download ZIP**.

   ```bash
   git clone https://github.com/DomTSM718/second-brain-template.git second-brain
   cd second-brain
   git remote remove origin
   ```

3. **Open it**: in the desktop app, go to **Code** → **Local** → **Select folder**, and choose `second-brain`.
4. **Make it yours**: ask Claude to *"help me fill in the User Profile section of CLAUDE.md, one question at a time"*.
5. **Start using it**:

   ```
   /new-project my-project
   /switch my-project
   /overview
   ```

Prefer the terminal? Install the CLI from https://code.claude.com/docs/en/setup and run `claude` inside the folder.

## Core Concepts

### The Vibe Engineering Workflow

```
PLAN → DELEGATE → ASSESS → CODIFY
  ↓         ↓         ↓        ↓
/plan    /work    /review   /learn
```

Each unit of work makes subsequent work easier through pattern extraction.

### Memory Types

| Type | Purpose | Location |
|------|---------|----------|
| **Semantic** | Facts, patterns, tech decisions | `memory/semantic/` |
| **Episodic** | Completed work records | `memory/episodic/` |
| **Procedural** | Workflows and processes | `memory/procedural/` |

### Projects

Each project contains:
- `context.md` - Tech stack, architecture, constraints
- `tasks.md` - Prioritized task list
- `patterns.md` - Project-specific patterns
- `notes.md` - Decisions, meeting notes

## Daily Workflow

### Morning
```
/overview              # See all urgent tasks
/switch [project]      # Load project context
```

### During Work
```
/plan [complex task]   # Break down big tasks
/step                  # Execute incrementally
```

### End of Day
```
/learn                 # Extract patterns from today's work
```

## Essential Commands

| Command | Purpose |
|---------|---------|
| `/switch [project]` | Load project context instantly |
| `/overview` | Morning dashboard of all tasks |
| `/plan [goal]` | Break complex tasks into steps |
| `/step` | Execute next planned step |
| `/learn` | Extract patterns from work |
| `/recall [topic]` | Search all memories |
| `/grow` | Brain health metrics |
| `/idea [text]` | Quick idea capture |
| `/add-task [desc]` | Add task to project |

## Repository Structure

```
.claude/
├── commands/          # Slash commands (pre-built)
├── skills/            # Executable workflows
├── agents/            # Specialized AI agents
├── hooks/             # Event hooks (bash scripts)
└── settings.json      # Permissions, safety and hook wiring

memory/
├── semantic/          # What you know
├── episodic/          # What you've done
└── procedural/        # How you do things

projects/
├── INDEX.md           # Project registry
├── _template/         # New project template
└── [your-projects]/   # Your actual projects

CLAUDE.md              # System instructions (CUSTOMIZE THIS)
```

## Customization Checklist

Before using, update these:

- [ ] **CLAUDE.md** → User Profile section (required)
- [ ] **.claude/settings.json** → Allow the tools you use (optional)
- [ ] **projects/** → Create your first project with `/new-project`
- [ ] **memory/semantic/tech/** → Document your tools and decisions

## Safety Features

Built-in protections in `.claude/settings.json`:
- Blocks destructive operations (`rm -rf`, etc.)
- Blocks network download tools (`curl`, `wget`, `nc`)
- Prevents privilege escalation (`sudo`, `su`)
- Blocks reading `.env` secrets files
- Incremental Git checkpoints during complex tasks

## Key Documents

- **GETTING_STARTED.md** - Setup and daily use (start here)
- **CLAUDE.md** - Complete system documentation
- **ONBOARDING.md** - Deeper walkthrough of each part of the system
- **.claude/settings.json** - Safety permissions and hook wiring

## Getting Help

- First time? → Read `GETTING_STARTED.md`
- Complex feature? → Use `/plan [goal]` → `/step`
- Ending session? → Run `/learn`
- Check progress → Run `/grow`
