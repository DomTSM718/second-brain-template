---
name: wrap-up
description: End-of-session close - the driver executes the mechanical steps, the agent does the three judgment steps, the gate proves both. Run before ending a session.
allowed-tools: Read, Write, Edit, Grep, Bash, Task
---

# Session Wrap-Up

Arming is automatic: the harness arms the gate the moment this prompt is submitted
(`.claude/hooks/prompt-arm-wrapup.sh`). Once armed, the session **cannot close** until
`wrap-up-gate.sh` is green - `.claude/hooks/stop-wrapup-gate.sh` enforces it on every
turn-end, whether or not I claim to be done. Nobody has to ask "is the gate green?".

## 1. Run the driver - it EXECUTES the mechanical steps

```bash
bash wrap-up-driver.sh
```

Archives `[x]` tasks (verify-before-replace, never destroys on mismatch), checks for
tracked env files and secret-shaped values, inventories untracked and modified files,
then prints a **FACTS block**. Act on every FACTS line before running the gate.

## 2. Three judgment steps - drop each marker only AFTER doing the step

**a. Active priorities** - REPLACE, never append, to the current stance. Anything that
must survive the session belongs in the project's `tasks.md`, not in prose. If you are
unsure whether priorities actually shifted, ask - do not stamp.
Then: `bash wrap-up-mark.sh priorities`

**b. Loose ends** - every item left for the human is tagged either **(a) owner-only
decision** or **(b) blocked-on:\<party\>**. Everything else is resolved or dropped now,
not carried. Dated or scheduled items need a self-resurfacing tracker.
Then: `bash wrap-up-mark.sh loose-ends`

**c. Cold read** - spawn a NO-context subagent (`general-purpose`, synchronous). Prompt,
without leaking the answers:

> *You are starting a work session with NO prior context. Read ONLY
> `projects/<current>/tasks.md`, plus `projects/<current>/context.md` for orientation.
> Answer: (1) the single next action and why; (2) what is waiting on the human; (3) what
> was done most recently and what the system state is; (4) what is unclear, contradictory
> or missing - quote exact wording, do not be charitable.*

**FIX what it finds, at source.** Then: `bash wrap-up-mark.sh cold-read`

## 3. Memory

If the session did significant work, write the episodic record under
`memory/episodic/completed-work/` and run `/learn` to extract patterns.

## 4. Gate

```bash
bash wrap-up-gate.sh
```

Green requires: clean tree, nothing unpushed, zero un-archived `[x]`, no env file tracked
by git, and all three judgment markers present and newer than the arming.

Fix every FACTS line first, then run the gate **once**. A red at that point means a step
was skipped, not that something new surfaced.

**Lead the summary with the cold read, not the check table:** *Next / Waiting on you
(tagged) / Just done / Unclear -> fixed*. Hygiene gets one line, naming only exceptions.

The cold reader's answer IS the deliverable. If it reads confused, the wrap-up is not
done, whatever the gate says.

## Adapting this to a repo

`wrap-up-driver.sh` and `wrap-up-gate.sh` each carry a marked repo-specific section at
the bottom. Put invariants that only matter here in those sections - a named production
credential, deploy-state drift, a second repo that must also be clean. Add each check to
**both**: the gate is what blocks, the driver is what surfaces it before you burn a red
cycle. Then add a short note below saying what this repo's close additionally proves.

## Repo-specific notes

- (none yet)
