#!/bin/bash
# verify-second-brain.sh <target-repo-path> [baseline-path]
#
# Audits a repo against the canonical second-brain baseline (EXPORT/).
# Exits 0 if complete, 1 if anything is missing or mis-wired.
#
# Usage:  bash tools/verify-second-brain.sh /c/Users/dominica/source/repos/MyRepo

set -uo pipefail

TARGET="${1:?usage: verify-second-brain.sh <target-repo-path> [baseline-path]}"
# Two layouts, one script: in the development repo the baseline is the curated
# EXPORT/ subfolder; in a clone of the shared template the repo root IS the
# baseline. Hardcoding ../EXPORT made this die with "baseline not found" when
# run from a clone, which is how every recipient would run it.
_SB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -n "${2:-}" ]; then
  BASELINE="$2"
elif [ -d "$_SB_ROOT/EXPORT/.claude" ]; then
  BASELINE="$_SB_ROOT/EXPORT"
else
  BASELINE="$_SB_ROOT"
fi

FAIL=0
pass() { printf '  \033[32mOK\033[0m   %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=1; }
warn() { printf '  \033[33mWARN\033[0m %s\n' "$1"; }

[ -d "$TARGET" ]   || { echo "target not found: $TARGET"; exit 1; }
[ -d "$BASELINE" ] || { echo "baseline not found: $BASELINE"; exit 1; }

echo "Verifying: $TARGET"
echo "Baseline:  $BASELINE"
echo

# --- 1. .claude payload: every baseline file must exist in target ---------
echo "[1] .claude payload (commands / skills / agents / hooks)"
for sub in commands skills agents hooks; do
  missing=0; total=0
  while IFS= read -r rel; do
    total=$((total+1))
    [ -f "$TARGET/.claude/$sub/$rel" ] || { fail ".claude/$sub/$rel"; missing=$((missing+1)); }
  done < <(cd "$BASELINE/.claude/$sub" && find . -type f | sed 's|^\./||')
  [ "$missing" -eq 0 ] && pass "$sub: $total/$total files present"
done

# --- 2. Memory / projects / brain-health scaffold -------------------------
echo
echo "[2] memory / projects / brain-health scaffold"
for rel in \
  memory/semantic memory/episodic memory/procedural \
  memory/episodic/INDEX.md memory/procedural/INDEX.md \
  projects/INDEX.md projects/_template/context.md projects/_template/tasks.md \
  projects/_template/patterns.md projects/_template/notes.md \
  brain-health/metrics.md brain-health/growth-log.md brain-health/pattern-confidence.md ; do
  [ -e "$TARGET/$rel" ] && pass "$rel" || fail "$rel"
done

# --- 3. Root documentation -----------------------------------------------
echo
echo "[3] root documentation"
for f in CLAUDE.md README.md ONBOARDING.md INSTALLATION_GUIDE.md SETUP_CHECKLIST.md .gitignore; do
  [ -f "$TARGET/$f" ] && pass "$f" || fail "$f"
done

# --- 4. Settings + hook wiring (the silent-failure check) -----------------
echo
echo "[4] settings + hook wiring"
S="$TARGET/.claude/settings.json"
if [ ! -f "$S" ]; then
  fail ".claude/settings.json missing (root settings.local.json is NOT read by Claude Code)"
else
  pass ".claude/settings.json exists"
  # Hooks must use the array form under the capitalised event name.
  if grep -q '"UserPromptSubmit"' "$S"; then pass "UserPromptSubmit hook declared"
  else fail "no UserPromptSubmit hook in .claude/settings.json"; fi
  if grep -q '"type"[[:space:]]*:[[:space:]]*"command"' "$S"; then pass "hook uses array/command form"
  else fail "hook is not in {type:command} array form - it will never fire"; fi
  if grep -q '"userPromptSubmit"' "$S"; then fail "lowercase 'userPromptSubmit' key found - wrong event name"; fi
  if grep -q '"deny"' "$S"; then pass "deny-list present"
  else fail "no permissions.deny block"; fi
  if command -v python >/dev/null 2>&1; then
    python -c "import json,sys;json.load(open(sys.argv[1]))" "$S" >/dev/null 2>&1 \
      && pass "settings.json is valid JSON" || fail "settings.json is NOT valid JSON"
  fi
fi

H="$TARGET/.claude/hooks/user-prompt-submit.sh"
if [ -f "$H" ]; then
  if grep -q 'USER_PROMPT="\$1"' "$H"; then
    fail "hook reads \$1 - Claude Code sends hook input as JSON on stdin, so phase detection is dead"
  else
    pass "hook reads its input from stdin"
  fi
fi

# --- 4b. Wrap-up close system --------------------------------------------
# The close is the highest-value part of the brain and the easiest to ship
# broken: the command can exist while the scripts it shells out to do not, and
# nothing complains until a session tries to close. Check all five pieces AND
# the wiring that makes the gate unskippable.
echo
echo "[4b] /wrap-up close system"
for rel in wrap-up-driver.sh wrap-up-gate.sh wrap-up-mark.sh \
           .claude/commands/wrap-up.md \
           .claude/hooks/prompt-arm-wrapup.sh \
           .claude/hooks/stop-wrapup-gate.sh ; do
  [ -f "$TARGET/$rel" ] && pass "$rel" || fail "$rel"
done
for rel in wrap-up-driver.sh wrap-up-gate.sh wrap-up-mark.sh; do
  if [ -f "$TARGET/$rel" ]; then
    bash -n "$TARGET/$rel" 2>/dev/null && pass "$rel parses" || fail "$rel has a syntax error"
  fi
done
if [ -f "$S" ]; then
  grep -q 'prompt-arm-wrapup.sh' "$S" \
    && pass "gate armed by UserPromptSubmit hook" \
    || fail "prompt-arm-wrapup.sh not wired in settings.json - /wrap-up will never arm"
  grep -q '"Stop"' "$S" && grep -q 'stop-wrapup-gate.sh' "$S" \
    && pass "gate enforced by Stop hook" \
    || fail "stop-wrapup-gate.sh not wired as a Stop hook - the close is unenforced"
fi
if [ -f "$TARGET/.gitignore" ]; then
  grep -q '\.wrap-up-armed' "$TARGET/.gitignore" \
    && pass ".gitignore excludes wrap-up session state" \
    || fail ".gitignore does not exclude .claude/.wrap-up-* - the gate will never see a clean tree"
fi

# --- 5. Personalisation --------------------------------------------------
echo
echo "[5] personalisation"
if grep -q '\[Your role/title\]' "$TARGET/CLAUDE.md" 2>/dev/null; then
  fail "CLAUDE.md still contains template placeholders ([Your role/title])"
else
  pass "CLAUDE.md user profile filled in"
fi
if grep -qri 'luca\|iwo\|szapar' "$TARGET/.claude" 2>/dev/null; then
  warn "third-party persona references found under .claude/"
else
  pass "no third-party persona references"
fi
if [ -f "$TARGET/projects/CURRENT" ]; then pass "projects/CURRENT seeded"; else warn "projects/CURRENT not set (run /switch)"; fi

echo
if [ "$FAIL" -eq 0 ]; then
  printf '\033[32mPASS\033[0m - second brain is complete and wired.\n'
else
  printf '\033[31mINCOMPLETE\033[0m - see FAIL lines above.\n'
fi
exit $FAIL
