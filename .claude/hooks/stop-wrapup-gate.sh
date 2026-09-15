#!/bin/bash
# Stop hook - WRAP-UP GATE SELF-ENFORCER (armed-flag triggered).
#
# The gap this closes: claim-triggered enforcement means a silent or trailed-off
# incomplete wrap-up slips through, and the human has to ask "is the gate green?"
# - which makes the human the enforcement. This makes it UNCONDITIONAL: while the
# armed flag is present and fresh, THIS hook runs wrap-up-gate.sh itself on every
# Stop and BLOCKS the close on red, regardless of what the agent did or did not
# claim.
#
# Lifecycle:
#   /wrap-up            -> prompt-arm-wrapup.sh arms the flag
#   each Stop, armed    -> re-run the gate:
#                            RED   -> exit 2 (cannot close; re-checks next Stop)
#                            GREEN -> clear flag + markers, exit 0
#   Freshness (<6h)     -> a stale flag from a crashed session cannot block an
#                          unrelated future session.
# Defensive: missing gate or unreadable flag -> exit 0. Never wedge the session
# on the enforcer's own failure.
set -u
cat >/dev/null 2>&1 || true   # consume stdin; unused - this hook keys off files

PROJ="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
FLAG="$PROJ/.claude/.wrap-up-armed"
GATE="$PROJ/wrap-up-gate.sh"

# Not armed -> nothing to enforce. Normal turns are untouched.
[ -f "$FLAG" ] || exit 0

armed_at="$(cat "$FLAG" 2>/dev/null)"
now="$(date +%s)"
if ! [ "$armed_at" -eq "$armed_at" ] 2>/dev/null; then
    rm -f "$FLAG" 2>/dev/null || true
    exit 0
fi
age=$((now - armed_at))
if [ "$age" -lt 0 ] || [ "$age" -ge 21600 ]; then   # 6h
    rm -f "$FLAG" 2>/dev/null || true
    exit 0
fi

if [ ! -f "$GATE" ]; then
    rm -f "$FLAG" 2>/dev/null || true
    exit 0
fi

GATE_OUT="$(bash "$GATE" 2>&1)"; GATE_RC=$?

if [ "$GATE_RC" -eq 0 ]; then
    # GREEN -> satisfied. Clear the flag AND this wrap-up's markers together, so a
    # manual gate run can never consume markers while still armed. The next
    # wrap-up must earn fresh ones.
    rm -f "$FLAG" \
          "$PROJ/.claude/.wrap-up-step-priorities" \
          "$PROJ/.claude/.wrap-up-step-loose-ends" \
          "$PROJ/.claude/.wrap-up-step-cold-read" 2>/dev/null || true
    exit 0
fi

{
  echo ""
  echo "WRAP-UP GATE - a /wrap-up was armed this session but wrap-up-gate.sh is RED."
  echo "   The session CANNOT close until the gate is green. This fires automatically,"
  echo "   whether or not the agent claimed 'done' - nobody has to ask. Fix the items"
  echo "   below, then end the turn again; the hook re-runs the gate and clears itself"
  echo "   on green."
  echo ""
  printf '%s\n' "$GATE_OUT" | grep -E '\[XX\]|GATE RED|uncommitted|not pushed|un-archived|TRACKED|STALE' | sed 's/^/   /' | head -20
  echo ""
} >&2
exit 2
