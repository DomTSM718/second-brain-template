#!/usr/bin/env bash
# wrap-up-mark.sh - drop a wrap-up judgment-step marker.
#
# WHY a script rather than an inline `date +%s > .claude/.wrap-up-step-*`: the
# inline shape prompts the permission matcher on every close, while `bash <script>`
# is allowlisted. Same write, no prompt, no permission loosened.
#
# Attestation semantics: run this ONLY AFTER doing the step. The gate checks the
# marker post-dates the arming, so a leftover from a previous close will not pass.
#
# Usage: bash wrap-up-mark.sh <priorities|loose-ends|cold-read>
set -u
PROJ="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

step="${1:-}"
case "$step" in
  priorities|loose-ends|cold-read) ;;
  *)
    echo "usage: bash wrap-up-mark.sh <priorities|loose-ends|cold-read>" >&2
    echo "  (drop the marker only AFTER doing the step - it attests the step ran)" >&2
    exit 1
    ;;
esac

mkdir -p "$PROJ/.claude" 2>/dev/null || true
mf="$PROJ/.claude/.wrap-up-step-$step"
if date +%s > "$mf" 2>/dev/null; then
  echo "marker dropped: $step ($(cat "$mf"))"
else
  echo "ERROR: could not write $mf" >&2
  exit 1
fi
