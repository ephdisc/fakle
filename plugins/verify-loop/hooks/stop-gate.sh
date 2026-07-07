#!/bin/bash
# verify-loop: Stop hook.
# Blocks ending the turn if code was edited but never exercised afterward.
# Blocks at most once per dirty window (a new edit re-arms it), so it can
# never loop forever.
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -z "$sid" ] && exit 0

dir="${VERIFY_LOOP_STATE_DIR:-$HOME/.claude/verify-loop-state}/state"
edit_f="$dir/$sid.edit"
verify_f="$dir/$sid.verify"
nudged_f="$dir/$sid.nudged"

# Nothing edited this session -> nothing to enforce.
[ -f "$edit_f" ] || exit 0

edit_ts=$(cat "$edit_f" 2>/dev/null || echo 0)
verify_ts=$(cat "$verify_f" 2>/dev/null || echo 0)
if [ "${verify_ts:-0}" -ge "${edit_ts:-0}" ] 2>/dev/null; then
  exit 0
fi

active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')
if [ "$active" = "true" ] || [ -f "$nudged_f" ]; then
  # Already nudged once for this dirty window; let the turn end but tell the user.
  echo '{"systemMessage":"verify-loop: turn ended with code changes that were never exercised (no test/run observed since the last edit)."}'
  exit 0
fi

touch "$nudged_f"
cat <<'JSON'
{"decision":"block","reason":"You edited code this session but nothing has been exercised since your last edit. Before finishing, verify your work yourself - do not hand verification back to the user. Concretely: (1) run the project's test suite if one exists, AND (2) actually drive the changed behavior end-to-end (run the app/scene/command/server and observe the real result, not just a green typecheck). For nontrivial changes, prefer spawning the 'verifier' agent for an independent fresh-context check. If verification is genuinely impossible here (missing device, credentials, external system), finish by stating explicitly what you could NOT verify and why, and give the user exact steps to verify it themselves."}
JSON
exit 0
