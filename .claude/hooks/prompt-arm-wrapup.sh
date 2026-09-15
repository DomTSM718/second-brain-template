#!/bin/bash
# UserPromptSubmit hook - HARNESS-SIDE arming of the wrap-up gate.
#
# WHY harness-side: the risk-creating event for "wrap-up skipped its own
# enforcement" is the /wrap-up invocation itself. If arming depended on the agent
# running a first step, a skipped first step means the Stop gate never fires and
# the close is unenforced. So the harness arms the flag the moment the user's
# prompt contains /wrap-up. While armed, stop-wrapup-gate.sh blocks session close
# until wrap-up-gate.sh is green.
#
# Fail-open: any self-failure exits 0. Never wedge a prompt on the enforcer.
set -u
PROJ="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
INPUT="$(cat 2>/dev/null || true)"

# System-generated turns are NOT user prompts. An agent report or task
# notification that QUOTES "/wrap-up" must not arm the gate.
if printf '%s' "$INPUT" | grep -Eq 'SYSTEM NOTIFICATION - NOT USER INPUT|<task-notification>'; then
    exit 0
fi

# Word-boundary match so /wrap-up-something does not arm.
if printf '%s' "$INPUT" | grep -Eq '/wrap-up([^a-zA-Z0-9-]|$)'; then
    FLAG="$PROJ/.claude/.wrap-up-armed"
    # Re-arm guard: arming again would RESET armed_at and turn every judgment
    # marker dropped so far STALE, forcing the judgment work to be redone
    # mid-close. While armed and fresh (<6h, the same window the Stop hook uses),
    # a further /wrap-up mention is a no-op. A stale or garbage flag re-arms.
    armed_at="$(cat "$FLAG" 2>/dev/null)"
    if [ "$armed_at" -eq "$armed_at" ] 2>/dev/null; then
        age=$(( $(date +%s) - armed_at ))
        if [ "$age" -ge 0 ] && [ "$age" -lt 21600 ]; then
            exit 0
        fi
    fi
    mkdir -p "$PROJ/.claude" 2>/dev/null || true
    date +%s > "$FLAG" 2>/dev/null || true
fi
exit 0
