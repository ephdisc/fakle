#!/bin/bash
# verify-loop: PostToolUse on Edit|Write|MultiEdit|NotebookEdit.
# Marks the session "dirty" (code changed, not yet exercised).
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -z "$sid" ] && exit 0

f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
# Docs, notes, and Claude's own config/scratch space don't need runtime verification.
case "$f" in
  ""|*.md|*.markdown|*.txt|*.rst|*.adoc) exit 0 ;;
  "$HOME/.claude/"*|/tmp/*|/private/tmp/*|/var/folders/*) exit 0 ;;
  */.claude/settings*.json|*/CLAUDE.md) exit 0 ;;
esac

dir="${VERIFY_LOOP_STATE_DIR:-$HOME/.claude/verify-loop-state}/state"
mkdir -p "$dir"
date +%s > "$dir/$sid.edit"
# A new edit resets the one-nudge-per-dirty-window allowance.
rm -f "$dir/$sid.nudged"
exit 0
