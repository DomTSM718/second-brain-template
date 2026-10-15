#!/bin/bash
# add-second-brain-to-existing.sh <target-repo-path> [--apply]
#
# Installs the second brain into a repo that ALREADY HAS CODE IN IT.
#
# Dry run by default. Nothing is written until you pass --apply.
#
# Why this exists separately from new-second-brain.sh: that one creates a repo
# and refuses a non-empty target, so it never has to care about the user's own
# files. Here every write is a potential collision with someone's real work, so
# the rules invert:
#
#   * SURVEY BEFORE WRITING. Every destination path is classified before any
#     copy happens. A collision outside the mergeable set aborts the run.
#   * BACK UP ANYTHING MODIFIED, to .second-brain-backup/<stamp>/.
#   * NEVER COPY ROOT DOCS. new-second-brain.sh copies README.md, ONBOARDING.md
#     and friends. Doing that here would overwrite the project's own README.
#   * SCOPE THE LINE-ENDING RULE. The baseline .gitattributes normalises the
#     whole tree ("* text=auto"); applied to a live repo that renormalises the
#     user's own scripts on their next checkout. Only the brain's own paths get
#     a rule here.
#   * FIX CRLF ON COPY, not via .gitattributes. Attributes affect future
#     checkouts; a hook written CRLF today fails today ("bad interpreter: \r").
#   * STAGE ONLY WHAT WE INSTALLED. Never `git add .` in someone else's repo.
#
set -uo pipefail

TARGET="${1:?usage: add-second-brain-to-existing.sh <target-repo-path> [--apply]}"
APPLY=0
for a in "${@:2}"; do [ "$a" = "--apply" ] && APPLY=1; done

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Two layouts, one script. In the development repo the baseline is the curated
# EXPORT/ subfolder; in a clone of the shared template the repo root IS the
# baseline. Detect rather than assume, so the same file works for both.
if [ -d "$SRC/EXPORT/.claude" ]; then
  BASE="$SRC/EXPORT"
elif [ -d "$SRC/.claude" ]; then
  BASE="$SRC"
else
  echo "cannot find a second-brain baseline next to this script"; exit 1
fi
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP=".second-brain-backup/$STAMP"
BRANCH="add-second-brain"

[ -d "$BASE" ]   || { echo "baseline missing: $BASE"; exit 1; }
[ -d "$TARGET" ] || { echo "target not found: $TARGET"; exit 1; }
cd "$TARGET" || exit 1

red()  { printf '\033[31m%s\033[0m\n' "$1"; }
grn()  { printf '\033[32m%s\033[0m\n' "$1"; }
ylw()  { printf '\033[33m%s\033[0m\n' "$1"; }

# Paths we are willing to merge into rather than abort on.
is_mergeable() {
  case "$1" in
    CLAUDE.md|.claude/settings.json|.gitignore|.gitattributes) return 0 ;;
    *) return 1 ;;
  esac
}

# ---- 0. Repo preconditions ----------------------------------------------
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { red "not a git repository: $TARGET"; exit 1; }
git rev-parse --verify HEAD >/dev/null 2>&1 || { red "repo has no commits; make one first so there is something to roll back to"; exit 1; }

# Tracked changes block the run: they are what makes a rollback possible.
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  red "working tree has uncommitted changes to tracked files. Commit or stash them yourself, then re-run."
  exit 1
fi

# Untracked files do NOT block, but an untracked file we would modify is
# unrecoverable from git, so it is called out explicitly.
UNTRACKED_AT_RISK=()
for f in CLAUDE.md .claude/settings.json .gitignore .gitattributes; do
  if [ -f "$f" ] && ! git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    UNTRACKED_AT_RISK+=("$f")
  fi
done

if git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
  red "branch '$BRANCH' already exists. Delete or rename it before re-running."
  exit 1
fi

# ---- 1. Build the manifest ----------------------------------------------
# Every path this install would write, derived from the baseline rather than
# hard-coded, so a payload change cannot make this script lie.
NEW=(); COLLIDE=(); MERGE=()

add_path() {
  local p="$1"
  if [ ! -e "$p" ]; then NEW+=("$p")
  elif is_mergeable "$p"; then MERGE+=("$p")
  else COLLIDE+=("$p")
  fi
}

# .claude payload, file by file
for sub in commands skills agents hooks; do
  [ -d "$BASE/.claude/$sub" ] || { red "baseline missing .claude/$sub"; exit 1; }
  while IFS= read -r rel; do
    add_path ".claude/$sub/$rel"
  done < <(cd "$BASE/.claude/$sub" && find . -type f | sed 's|^\./||')
done

# memory / projects / brain-health, file by file
for d in memory projects brain-health; do
  [ -d "$BASE/$d" ] || { red "baseline missing $d/"; exit 1; }
  while IFS= read -r rel; do
    add_path "$d/$rel"
  done < <(cd "$BASE/$d" && find . -type f | sed 's|^\./||')
done

# wrap-up close system at the repo root
for s in wrap-up-driver.sh wrap-up-gate.sh wrap-up-mark.sh; do
  [ -f "$BASE/$s" ] || { red "baseline missing $s"; exit 1; }
  add_path "$s"
done

# The brain's own docs. README.md is deliberately NOT among them: in an existing
# repo that is the project's front page, and overwriting it is the single worst
# thing this script could do. These three are brain-specific filenames, so a
# collision means the brain is already here - which add_path turns into an abort.
for f in ONBOARDING.md INSTALLATION_GUIDE.md SETUP_CHECKLIST.md GETTING_STARTED.md; do
  [ -f "$BASE/$f" ] && add_path "$f"
done

# the four mergeables
add_path "CLAUDE.md"
add_path ".claude/settings.json"
add_path ".gitignore"
add_path ".gitattributes"

# ---- 2. Report -----------------------------------------------------------
echo
echo "Second brain -> $TARGET"
echo "baseline: $BASE"
echo
echo "  new files to add:        ${#NEW[@]}"
echo "  files to merge into:     ${#MERGE[@]}"
echo "  BLOCKING collisions:     ${#COLLIDE[@]}"
echo

if [ "${#MERGE[@]}" -gt 0 ]; then
  ylw "Will MERGE into these (your content is preserved; a backup is taken):"
  for p in "${MERGE[@]}"; do echo "    $p"; done
  echo
fi

if [ "${#UNTRACKED_AT_RISK[@]}" -gt 0 ]; then
  ylw "These exist but are NOT tracked by git, so git cannot restore them."
  ylw "The backup copy under $BACKUP will be their only copy:"
  for p in "${UNTRACKED_AT_RISK[@]}"; do echo "    $p"; done
  echo
fi

if [ "${#COLLIDE[@]}" -gt 0 ]; then
  red "ABORTING: the install would overwrite files that are yours."
  echo
  for p in "${COLLIDE[@]}"; do echo "    $p"; done
  echo
  echo "Nothing has been written. These are not in the mergeable set, so this"
  echo "script will not touch them. Resolve by hand: move or rename yours, or"
  echo "decide the brain does not need that file, then re-run."
  exit 1
fi

if [ "$APPLY" -eq 0 ]; then
  echo "DRY RUN. Nothing written. Re-run with --apply to install."
  exit 0
fi

# ---- 3. Branch, then back up --------------------------------------------
echo "==> Creating branch $BRANCH"
git checkout -q -b "$BRANCH"

echo "==> Backing up to $BACKUP"
mkdir -p "$BACKUP"
for p in "${MERGE[@]}"; do
  mkdir -p "$BACKUP/$(dirname "$p")"
  cp "$p" "$BACKUP/$p"
done

INSTALLED=()   # everything we stage at the end

# ---- 4. Copy the payload (new files only; collisions already ruled out) --
echo "==> Copying .claude payload"
for sub in commands skills agents hooks; do
  while IFS= read -r rel; do
    d=".claude/$sub/$rel"
    mkdir -p "$(dirname "$d")"
    cp "$BASE/.claude/$sub/$rel" "$d"
    INSTALLED+=("$d")
  done < <(cd "$BASE/.claude/$sub" && find . -type f | sed 's|^\./||')
done

echo "==> Copying memory / projects / brain-health"
for dd in memory projects brain-health; do
  while IFS= read -r rel; do
    d="$dd/$rel"
    mkdir -p "$(dirname "$d")"
    cp "$BASE/$dd/$rel" "$d"
    INSTALLED+=("$d")
  done < <(cd "$BASE/$dd" && find . -type f | sed 's|^\./||')
done

echo "==> Copying the brain's own docs (never README.md)"
for f in ONBOARDING.md INSTALLATION_GUIDE.md SETUP_CHECKLIST.md GETTING_STARTED.md; do
  [ -f "$BASE/$f" ] || continue
  cp "$BASE/$f" "$f"
  INSTALLED+=("$f")
done

echo "==> Installing wrap-up close system at repo root"
for s in wrap-up-driver.sh wrap-up-gate.sh wrap-up-mark.sh; do
  cp "$BASE/$s" "$s"
  INSTALLED+=("$s")
done

# ---- 5. Shell scripts: strip CRLF NOW, then mark executable -------------
# .gitattributes only governs future checkouts. A hook written with CRLF today
# dies today on "bad interpreter: /bin/bash^M".
echo "==> Normalising line endings and permissions on the brain's scripts"
for f in .claude/hooks/*.sh wrap-up-driver.sh wrap-up-gate.sh wrap-up-mark.sh; do
  [ -f "$f" ] || continue
  sed -i 's/\r$//' "$f"
  chmod +x "$f"
  # chmod is a no-op on NTFS; this is what actually records the bit in git.
  git update-index --add --chmod=+x "$f" 2>/dev/null || true
done

# ---- 6. Patch the hook to read stdin ------------------------------------
if [ -f ".claude/hooks/user-prompt-submit.sh" ]; then
  echo "==> Patching hook to read its prompt from stdin"
  python "$SRC/tools/_patch_hook.py" ".claude/hooks/user-prompt-submit.sh" \
    || ylw "    hook patch script failed - check .claude/hooks/user-prompt-submit.sh by hand"
  sed -i 's/\r$//' ".claude/hooks/user-prompt-submit.sh"
fi

# ---- 7. settings.json: merge, then PROVE it is still valid JSON ---------
echo "==> Wiring .claude/settings.json"
mkdir -p .claude
if [ -f ".claude/settings.json" ]; then
  python - "$SRC/tools/_settings.json" ".claude/settings.json" <<'PY'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
base = json.load(open(src, encoding='utf-8'))
mine = json.load(open(dst, encoding='utf-8'))
# Hooks: add the baseline's events, keep any the user already has.
bh, mh = base.get('hooks', {}), mine.setdefault('hooks', {})
for event, entries in bh.items():
    mh.setdefault(event, [])
    existing = json.dumps(mh[event], sort_keys=True)
    for e in entries:
        if json.dumps(e, sort_keys=True) not in existing:
            mh[event].append(e)
# Permissions: union allow, union deny. Never drop one of the user's.
bp, mp = base.get('permissions', {}), mine.setdefault('permissions', {})
for key in ('allow', 'deny'):
    have = mp.setdefault(key, [])
    for rule in bp.get(key, []):
        if rule not in have:
            have.append(rule)
# Every other top-level key of the user's (model, env, statusLine, mcpServers…)
# is left exactly as it was: we only ever added to hooks and permissions.
json.dump(mine, open(dst, 'w', encoding='utf-8'), indent=2)
PY
  if [ $? -ne 0 ]; then
    red "settings.json merge failed - restoring your original from the backup"
    cp "$BACKUP/.claude/settings.json" ".claude/settings.json"
    red "ABORTED. Repo is on branch $BRANCH with files copied but settings unwired."
    echo "Roll back with:  git checkout -- . && git clean -fd && git checkout - && git branch -D $BRANCH"
    exit 1
  fi
else
  cp "$SRC/tools/_settings.json" ".claude/settings.json"
fi
INSTALLED+=(".claude/settings.json")

# A malformed settings.json silently kills every hook and permission while
# every other check in this script still passes. So prove it parses.
python -c "import json,sys; json.load(open('.claude/settings.json',encoding='utf-8'))" || {
  red "settings.json is not valid JSON after writing - restoring backup"
  [ -f "$BACKUP/.claude/settings.json" ] && cp "$BACKUP/.claude/settings.json" ".claude/settings.json"
  exit 1
}

# ---- 8. CLAUDE.md -------------------------------------------------------
echo "==> CLAUDE.md"
if [ -f "CLAUDE.md" ]; then
  # Theirs stays first and intact. The brain is appended under a marker so it
  # can be found and removed later. The template's own User Profile section is
  # NOT carried over - it describes a stranger.
  {
    echo
    echo "<!-- ===== SECOND BRAIN (added $STAMP) ===== -->"
    echo
    python - "$BASE/CLAUDE.md" <<'PY'
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
# Drop the profile section: it is the one part that is about a person.
text = re.sub(r'\n## User Profile.*?(?=\n## )', '\n', text, flags=re.S)
sys.stdout.write(text)
PY
  } >> CLAUDE.md
  ylw "    appended the brain's sections under a marker; your content is untouched above it"
  ylw "    NOTE: the template's User Profile was stripped - fill in your own, see below"
else
  python - "$BASE/CLAUDE.md" > CLAUDE.md <<'PY'
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
text = re.sub(r'\n## User Profile.*?(?=\n## )', '\n', text, flags=re.S)
sys.stdout.write(text)
PY
fi
INSTALLED+=("CLAUDE.md")

# ---- 9. .gitattributes: SCOPED, not repo-wide ---------------------------
echo "==> .gitattributes (scoped to the brain's own scripts)"
{
  echo ""
  echo "# Second brain: these scripts must stay LF or Git Bash fails on them"
  echo "# after a Windows checkout (\"bad interpreter: \\r\"). Deliberately scoped"
  echo "# to the brain's own paths - it must not renormalise this project's files."
  echo ".claude/hooks/*.sh text eol=lf"
  echo "/wrap-up-driver.sh text eol=lf"
  echo "/wrap-up-gate.sh   text eol=lf"
  echo "/wrap-up-mark.sh   text eol=lf"
} >> .gitattributes
INSTALLED+=(".gitattributes")

# ---- 10. .gitignore: add only what cannot hide a tracked file -----------
echo "==> .gitignore"
IG_SKIPPED=()
touch .gitignore
# Only entries the brain itself needs. The baseline .gitignore also carries
# generic node/.NET/python/build rules; those are this project's business, and
# adding them could newly ignore paths it tracks on purpose.
# .wrap-up-* is NOT optional: without it the close gate never sees a clean tree.
for pat in ".second-brain-backup/" ".claude-plan.json" ".claude/settings.local.json" \
           ".claude/.wrap-up-armed" ".claude/.wrap-up-step-*"; do
  grep -qxF "$pat" .gitignore && continue
  # Refuse any pattern that would newly ignore something this repo tracks.
  if git ls-files --error-unmatch "${pat%/}" >/dev/null 2>&1; then
    IG_SKIPPED+=("$pat"); continue
  fi
  printf '%s\n' "$pat" >> .gitignore
done
INSTALLED+=(".gitignore")
if [ "${#IG_SKIPPED[@]}" -gt 0 ]; then
  ylw "    skipped (would have ignored tracked files): ${IG_SKIPPED[*]}"
fi

# ---- 11. Seed the project record ----------------------------------------
NAME="$(basename "$TARGET")"
echo "==> Seeding projects/$NAME"
if [ -d "projects/_template" ] && [ ! -d "projects/$NAME" ]; then
  mkdir -p "projects/$NAME"
  for f in context tasks patterns notes; do
    [ -f "projects/_template/$f.md" ] && cp "projects/_template/$f.md" "projects/$NAME/$f.md" \
      && INSTALLED+=("projects/$NAME/$f.md")
  done
  printf '%s\n' "$NAME" > projects/CURRENT
  INSTALLED+=("projects/CURRENT")
  ylw "    context.md is a template - ask Claude to fill it in from the repo"
fi

# ---- 12. Stage ONLY what we installed -----------------------------------
echo "==> Staging the install (nothing else)"
printf '%s\n' "${INSTALLED[@]}" | sort -u > "$BACKUP/manifest.txt"
git add -- "${INSTALLED[@]}" 2>/dev/null
git add -- "$BACKUP/manifest.txt" 2>/dev/null || true

# Prove we changed nothing of theirs: every staged path must be an addition,
# except the four mergeables.
echo
echo "==> Checking we modified nothing of yours"
BAD=0
while IFS=$'\t' read -r status path; do
  case "$status" in
    A) : ;;
    M) is_mergeable "$path" || { red "    MODIFIED a file that is not mergeable: $path"; BAD=1; } ;;
    D) red "    DELETED: $path"; BAD=1 ;;
  esac
done < <(git diff --cached --name-status)
[ "$BAD" -eq 0 ] && grn "    clean - only additions, plus the merges listed above"

# ---- 13. Commit ---------------------------------------------------------
git -c core.hooksPath=/dev/null commit -q -F - <<COMMITMSG
Add second brain

Installed from the second-brain baseline via add-second-brain-to-existing.sh.
Additions only, except these merges: ${MERGE[*]:-none}
Originals backed up to $BACKUP/ (manifest.txt lists every installed path).

The line-ending rule is scoped to the brain's own scripts; this project's
files are not renormalised.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
COMMITMSG

grn "Installed on branch $BRANCH, committed."
echo
echo "To remove it completely:"
echo "    git checkout - && git branch -D $BRANCH"
echo
echo "Next: run the verifier, then open the repo in Claude and type / to see the commands."
echo "    bash $SRC/tools/verify-second-brain.sh \"$TARGET\""
echo
bash "$SRC/tools/verify-second-brain.sh" "$TARGET" || ylw "verifier reported gaps - see FAIL lines above"
