#!/usr/bin/env bash
# wrap-up-gate.sh - ONE atomic completion gate for /wrap-up.
# ------------------------------------------------------------------------------
# Portable baseline version. Covers only MECHANICAL invariants - everything a
# script can decide:
#   1. working tree clean
#   2. nothing unpushed (informational while there is no remote)
#   3. tasks.md: no un-archived [x]
#   4. no env file tracked by git
#   5. three judgment markers present AND newer than the arming timestamp
#
# It cannot judge whether a parked item is legitimate or whether the priorities
# block is honest. Those stay forced procedural steps in the command; the gate
# only refuses to let the session close without attesting they were done.
#
# Repo-specific invariants (deploy-state drift, merged-PR reconcile, a named
# production credential, a second repo that must also be clean) go in the marked
# section near the bottom. A check only blocks if it lives HERE - the driver
# reports, the gate decides.
#
# Exit 0 = green. Exit 1 = at least one failure.
set -u

PROJ="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
cd "$PROJ" || exit 1

FAIL=0
pass() { printf '  [ok] %s\n' "$1"; }
fail() { printf '  [XX] %s\n' "$1"; FAIL=1; }
info() { printf '   .   %s\n' "$1"; }

# Same resolution as wrap-up-driver.sh: projects/CURRENT if set, else every
# non-template project. Keep the two in step, or the driver will archive a file
# the gate never checks.
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

# Must match wrap-up-driver.sh exactly. The task templates document their format
# inside <!-- --> blocks containing literal "- [x]" lines; counting those makes
# the gate demand the archiving of documentation the driver correctly refuses to
# touch, and the close can never go green.
AWK_COMMENT_STATE='{
  was = inc
  n_open  = gsub(/<!--/, "<!--")
  n_close = gsub(/-->/,  "-->")
  if (n_open > n_close) inc = 1; else if (n_close > n_open) inc = 0
  incomment = (was == 1 || n_open > 0)
}'
count_x() { awk "$AWK_COMMENT_STATE"' !incomment && /^- \[x\]/ {n++} END{print n+0}' "$1"; }

echo "=== WRAP-UP GATE - mechanical invariants ==="

# Every git invocation costs ~1-2s of process startup on Windows, and the Stop
# hook re-runs this whole gate on EVERY turn-end while armed. So probe once and
# reuse, rather than asking "is this a git tree?" in each section.
IS_GIT=0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && IS_GIT=1

# --- 1 + 2: repo clean and pushed ---
if [ "$IS_GIT" -eq 1 ]; then
  dirty="$(git status --porcelain 2>/dev/null)"
  if [ -n "$dirty" ]; then
    fail "working tree: $(printf '%s\n' "$dirty" | grep -c .) uncommitted change(s)"
    printf '%s\n' "$dirty" | sed 's/^/        /' | head -10
  else
    pass "working tree clean"
  fi
  up="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
  if [ -n "$up" ]; then
    ahead="$(git rev-list --count "${up}..HEAD" 2>/dev/null || echo 0)"
    if [ "${ahead:-0}" -gt 0 ] 2>/dev/null; then
      fail "$ahead commit(s) not pushed to $up"
    else
      pass "pushed (== $up)"
    fi
  else
    info "no upstream configured - cannot verify pushed (local-only repo)"
  fi
else
  info "not a git tree - skipped"
fi

# --- 3: no un-archived completed tasks ---
checked=0
while IFS= read -r TASKS; do
  [ -n "$TASKS" ] || continue
  checked=1
  xc="$(count_x "$TASKS")"
  if [ "${xc:-0}" -eq 0 ] 2>/dev/null; then
    pass "$TASKS: 0 un-archived [x]"
  else
    fail "$TASKS: $xc completed [x] task(s) not archived - run bash wrap-up-driver.sh"
  fi
done <<< "$(task_files)"
[ "$checked" -eq 1 ] || info "no project tasks.md to check (base-only install)"

# --- 4: secrets ---
# A tracked env file is the one mistake a later commit cannot undo. Value-shaped
# scanning is report-only in the driver; promote a specific variable to a hard
# failure below when this repo actually holds one.
if [ "$IS_GIT" -eq 1 ]; then
  envtracked="$(git ls-files 2>/dev/null \
    | grep -E '(^|/)\.env($|\.)' \
    | grep -Ev '\.env\.(example|template|sample)$' || true)"
  if [ -n "$envtracked" ]; then
    fail "env file(s) TRACKED by git - untrack before this can go green:"
    printf '%s\n' "$envtracked" | sed 's/^/        /'
  else
    pass "no env files tracked"
  fi
fi

# --- 5: judgment markers, and they must post-date the arming ---
# A marker older than armed_at is left over from a previous close: it attests
# nothing about this session.
ARMED="$PROJ/.claude/.wrap-up-armed"
armed_at="$(cat "$ARMED" 2>/dev/null || echo 0)"
[ "$armed_at" -eq "$armed_at" ] 2>/dev/null || armed_at=0
for step in priorities loose-ends cold-read; do
  mf="$PROJ/.claude/.wrap-up-step-$step"
  at="$(cat "$mf" 2>/dev/null || echo 0)"
  [ "$at" -eq "$at" ] 2>/dev/null || at=0
  if [ "$at" -eq 0 ]; then
    fail "judgment step not done: $step  (bash wrap-up-mark.sh $step, AFTER doing it)"
  elif [ "$at" -lt "$armed_at" ]; then
    fail "judgment marker STALE: $step (predates this wrap-up) - redo it"
  else
    pass "judgment step attested: $step"
  fi
done

# --- 6..: REPO-SPECIFIC INVARIANTS ---------------------------------------
# Add hard checks for this repo here, each calling fail() so it blocks. Mirror
# every one in wrap-up-driver.sh so it surfaces BEFORE the gate run rather than
# costing a red cycle.

echo
if [ "$FAIL" -eq 0 ]; then
  echo "=== GATE GREEN ==="
  echo "Reminder (not script-checkable): every remaining loose end is tagged"
  echo "(a) owner-only decision or (b) blocked-on:<party>, or it was resolved/dropped."
  exit 0
fi
echo "=== GATE RED - wrap-up is NOT done ==="
exit 1
