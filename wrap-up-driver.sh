#!/usr/bin/env bash
# wrap-up-driver.sh - EXECUTES the mechanical close steps, then reports FACTS.
#
# Principle: execution over instruction. A script cannot skip its own steps, so
# the driver DOES the mechanical work and leaves the agent only the judgment
# steps. It always exits 0 - it is an executor and reporter, never the pass/fail
# authority. That is wrap-up-gate.sh.
#
# Portable baseline version: project-agnostic (resolves projects from
# projects/CURRENT, falling back to every non-template project) and free of
# repo-specific checks. Add repo-specific checks in the marked section near the
# bottom, and mirror each one in wrap-up-gate.sh so it actually blocks.
#
# Pure bash/grep/awk. Fail-open: a failed sub-step is REPORTED, never swallowed,
# and tasks.md is never left half-written (verify-before-replace).
set -u
PROJ="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
cd "$PROJ" || exit 0

TODAY="$(date +%F)"
FACTS=""
note() { FACTS="${FACTS}  - $1
"; }

# Every real project task list. projects/CURRENT names the active one; without
# it (a base-only install, or before the first /switch) fall back to every
# project directory, skipping the _template scaffold.
task_files() {
  local cur=""
  # Guard the read rather than redirecting tr's stderr: 2>/dev/null covers tr,
  # not the shell's own "no such file" for a failed < redirect, so a base-only
  # repo with no projects/CURRENT yet printed an error on every close.
  [ -f projects/CURRENT ] && cur="$(tr -d '\r' < projects/CURRENT | head -1)"
  if [ -n "$cur" ] && [ -f "projects/$cur/tasks.md" ]; then
    printf '%s\n' "projects/$cur/tasks.md"
    return
  fi
  find projects -mindepth 2 -maxdepth 2 -name tasks.md 2>/dev/null | grep -v '/_template/'
}

# The task templates document their own format inside <!-- --> blocks, and those
# examples contain literal "- [x]" lines. Treating those as real completed tasks
# archives the documentation and leaves a dangling "-->" behind in tasks.md, so
# every checkbox scan below has to know whether it is inside a comment.
# A line counts as commented if it opened a comment or a previous line did.
AWK_COMMENT_STATE='{
  was = inc
  n_open  = gsub(/<!--/, "<!--")
  n_close = gsub(/-->/,  "-->")
  if (n_open > n_close) inc = 1; else if (n_close > n_open) inc = 0
  incomment = (was == 1 || n_open > 0)
}'

count_x()    { awk "$AWK_COMMENT_STATE"' !incomment && /^- \[x\]/ {n++} END{print n+0}' "$1"; }
count_open() { awk "$AWK_COMMENT_STATE"' !incomment && /^- \[ \]/ {n++} END{print n+0}' "$1"; }

echo "=== WRAP-UP DRIVER - executing mechanical close steps ==="

# --- D0: arm the gate (the UserPromptSubmit hook arms it too) ---
# Re-arm guard: writing a fresh timestamp moves armed_at FORWARD, which the gate
# reads as making every marker dropped so far STALE. Re-running the driver
# mid-close is encouraged, so an unguarded write here would silently expire
# earned markers and demand the judgment work be redone.
ARMED_FLAG=".claude/.wrap-up-armed"
mkdir -p .claude 2>/dev/null || true
armed_at="$(cat "$ARMED_FLAG" 2>/dev/null)"
now="$(date +%s)"
if [ "$armed_at" -eq "$armed_at" ] 2>/dev/null \
   && [ "$((now - armed_at))" -ge 0 ] && [ "$((now - armed_at))" -lt 21600 ]; then
  echo "  [D0] gate already armed $(( (now - armed_at) / 60 ))m ago - left alone"
else
  date +%s > "$ARMED_FLAG" 2>/dev/null && echo "  [D0] gate armed" \
    || echo "  [D0] WARN: could not arm gate flag"
fi

# --- D1: archive completed [x] tasks (verify-before-replace) ---
found_tasks=0
while IFS= read -r TASKS; do
  [ -n "$TASKS" ] || continue
  found_tasks=1
  ARCHIVE="$(dirname "$TASKS")/tasks-archive.md"
  xc="$(count_x "$TASKS")"
  oc_before="$(count_open "$TASKS")"
  if [ "$xc" -eq 0 ] 2>/dev/null; then
    echo "  [D1] $TASKS: no [x] tasks to archive"
    continue
  fi
  blocks="$(awk "$AWK_COMMENT_STATE"'
    !incomment && /^- \[x\]/ {b=1;print;next}
    incomment {b=0;next}
    /^- \[/{b=0} /^#/{b=0} b{print}' "$TASKS")"
  tmp="$(mktemp)"
  awk "$AWK_COMMENT_STATE"'
    !incomment && /^- \[x\]/ {b=1;next}
    incomment {b=0;print;next}
    /^- \[/{b=0} /^#/{b=0} !b{print}' "$TASKS" > "$tmp"
  xc_after="$(count_x "$tmp")"
  oc_after="$(count_open "$tmp")"
  if [ "$xc_after" -eq 0 ] && [ "$oc_after" -eq "$oc_before" ]; then
    [ -f "$ARCHIVE" ] || printf '# Tasks Archive\n\nCompleted tasks, newest section last.\n' > "$ARCHIVE"
    { echo ""; echo "## Archived $TODAY (driver)"; echo ""; printf '%s\n' "$blocks"; } >> "$ARCHIVE"
    mv "$tmp" "$TASKS"
    echo "  [D1] $TASKS: archived $xc [x] task(s); open count unchanged ($oc_before)"
    note "archived $xc completed task(s) to $ARCHIVE"
  else
    rm -f "$tmp"
    echo "  [D1] $TASKS: ABORTED archive: verify failed ([x] after=$xc_after, [ ] $oc_before->$oc_after) - file untouched"
    note "ARCHIVE ABORTED on $TASKS (verify mismatch) - needs a manual look"
  fi
done <<< "$(task_files)"
if [ "$found_tasks" -eq 0 ]; then
  echo "  [D1] no project tasks.md found (base-only install? run /new-project)"
fi

# --- D2: secrets ---
# Hard rule everywhere: a tracked .env is unrecoverable once pushed. The
# value-pattern sweep below is REPORT-ONLY in the baseline - a generic pattern
# has false positives, and a false red blocks the close. Promote the ones that
# matter for THIS repo to hard failures in wrap-up-gate.sh's repo-specific section.
# Probed once and reused below: each git call costs ~1-2s of process startup on
# Windows, and the close already runs the driver and the gate back to back.
IS_GIT=0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && IS_GIT=1

if [ "$IS_GIT" -eq 1 ]; then
  envtracked="$(git ls-files 2>/dev/null \
    | grep -E '(^|/)\.env($|\.)' \
    | grep -Ev '\.env\.(example|template|sample)$' || true)"
  if [ -n "$envtracked" ]; then
    echo "  [D2] env file(s) TRACKED by git:"
    printf '%s\n' "$envtracked" | sed 's/^/         /'
    note "URGENT: tracked env file(s) - untrack before committing anything"
  else
    echo "  [D2] no env files tracked"
  fi
  # Placeholder values are filtered out: the docs and agent files are full of
  # API_KEY=your_api_key_here, and a FACTS line that cries wolf on every close
  # is a FACTS line nobody reads. Exclude the wrap-up scripts and .gitignore too
  # - they carry the pattern as text.
  leak="$(git ls-files -z 2>/dev/null \
    | xargs -0 grep -n -E '^[A-Za-z0-9_]*(PASSWORD|PASSWD|SECRET|API_?KEY|ACCESS_KEY|PRIVATE_KEY|CONNECTION_STRING)[A-Za-z0-9_]*=[^[:space:]]' 2>/dev/null \
    | grep -Eiv '=["'"'"']?(your|my|the|a_|xxx|changeme|change_me|placeholder|example|sample|dummy|fake|todo|test|insert|<|\$\{|%)' \
    | grep -Eiv '(_here|-here|your_|your-|\.\.\.|\bhere\b)' \
    | cut -d: -f1 | sort -u \
    | grep -Ev '(wrap-up-.*\.sh|\.gitignore)$' || true)"
  if [ -n "$leak" ]; then
    echo "  [D2] secret-shaped assignment(s) in tracked file(s) - CHECK each:"
    printf '%s\n' "$leak" | sed 's/^/         /'
    note "secret-shaped values in tracked file(s) - confirm each is a placeholder, not a real credential"
  fi
fi

# --- D3: untracked inventory (a commit decision, not a script decision) ---
untracked="$(git ls-files --others --exclude-standard 2>/dev/null | head -40)"
if [ -n "$untracked" ]; then
  n="$(printf '%s\n' "$untracked" | grep -c .)"
  echo "  [D3] $n untracked path(s):"
  printf '%s\n' "$untracked" | sed 's/^/         /'
  note "$n untracked path(s) - decide commit or ignore for EACH before the gate can go green"
else
  echo "  [D3] nothing untracked"
fi

# --- D4: modified-file inventory ---
modified="$(git diff --name-only 2>/dev/null)"
if [ -n "$modified" ]; then
  n="$(printf '%s\n' "$modified" | grep -c .)"
  echo "  [D4] $n modified file(s)"
  note "$n modified file(s) uncommitted - commit or revert"
fi

# --- D5: scratchpad inventory (triage is judgment; the listing is mechanical) ---
for cand in "${CLAUDE_SCRATCHPAD:-}" "${TMPDIR:-}" "${TEMP:-}" "${TMP:-}"; do
  [ -n "$cand" ] && [ -d "$cand" ] || continue
  # grep -c prints its count AND exits 1 on no-match; `|| echo 0` would append a
  # SECOND line, printing a doubled zero. Capture the print, default the empty case.
  cnt="$(find "$cand" -maxdepth 3 -type f 2>/dev/null | grep -c .)"; cnt="${cnt:-0}"
  echo "  [D5] scratch $cand: $cnt file(s) (report-only)"
  break
done

# --- D6..: REPO-SPECIFIC CHECKS ------------------------------------------
# Add checks that only make sense for this repo here (deploy-state drift,
# merged-PR reconcile, a named credential, a second repo that must also be
# clean). Anything that must BLOCK the close needs a matching check in
# wrap-up-gate.sh - the driver only reports.

echo
echo "=== FACTS for the judgment steps ==="
if [ -z "$FACTS" ]; then
  echo "  - nothing mechanical outstanding"
else
  printf '%s' "$FACTS"
fi
echo
echo "Judgment steps now - each drops its marker only AFTER the step is done:"
echo "  1. ACTIVE PRIORITIES: replace (never append) to current stance"
echo "       -> bash wrap-up-mark.sh priorities"
echo "  2. Loose ends: every item tagged (a) owner-only decision or (b) blocked-on:<party>,"
echo "     else resolved or dropped now"
echo "       -> bash wrap-up-mark.sh loose-ends"
echo "  3. Cold read: no-context subagent reads tasks.md only; FIX what it finds at source"
echo "       -> bash wrap-up-mark.sh cold-read"
echo
echo "Then: bash wrap-up-gate.sh - ONE run, after every FACTS line is dealt with."
echo "  A red at that point means a step was skipped, not that something new surfaced."
