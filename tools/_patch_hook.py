# Patches user-prompt-submit.sh to read its prompt from stdin JSON.
# Claude Code sends hook input as JSON on stdin; the shipped script read "$1",
# which left USER_PROMPT empty and made every prompt fall through to the
# default "execution" phase.
# Usage: python _patch_hook.py <path-to-hook>
import io
import sys

path = sys.argv[1]
s = io.open(path, encoding="utf-8").read()

OLD = '# Get the user\'s prompt\nUSER_PROMPT="$1"'

NEW = """# Claude Code delivers hook input as JSON on stdin (field: .prompt).
# Reading "$1" leaves USER_PROMPT empty and kills phase detection.
HOOK_INPUT="$(cat)"
if command -v jq >/dev/null 2>&1; then
  USER_PROMPT="$(printf '%s' "$HOOK_INPUT" | jq -r '.prompt // ""' 2>/dev/null)"
else
  USER_PROMPT="$(printf '%s' "$HOOK_INPUT" \\
    | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\\([^"]*\\)".*/\\1/p')"
fi
# Fall back to argv so the script stays testable from the command line.
[ -z "$USER_PROMPT" ] && USER_PROMPT="${1:-}\""""

if OLD not in s:
    if "HOOK_INPUT=" in s:
        print("   hook already patched - skipping")
        sys.exit(0)
    sys.exit("ERROR: hook patch point not found; the upstream hook script changed")

io.open(path, "w", encoding="utf-8", newline="\n").write(s.replace(OLD, NEW, 1))
print("   hook now reads stdin JSON")
