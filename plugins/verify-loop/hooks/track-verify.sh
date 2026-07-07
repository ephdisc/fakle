#!/bin/bash
# verify-loop: PostToolUse on Bash and mcp__* tools.
# Records a "verification event" when the session exercises code:
# test runners, running the app/scene, hitting a local server, or
# MCP tools that run/inspect a live program.
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -z "$sid" ] && exit 0
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')

verified=0
if [ "$tool" = "Bash" ]; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
  if printf '%s' "$cmd" | grep -qiE '(^|[;&| ])(pytest|jest|vitest|mocha|phpunit|rspec|tox|nox|ctest|busted|gdunit|gut_cmdln)' \
    || printf '%s' "$cmd" | grep -qiE '(go|cargo|npm|yarn|pnpm|bun|deno|dotnet|mvn|gradle|gradlew|make|mix|swift|flutter|zig) +(run +)?test' \
    || printf '%s' "$cmd" | grep -qiE '(npm|yarn|pnpm|bun|deno) +(run +)?(dev|start|serve|preview)' \
    || printf '%s' "$cmd" | grep -qiE '(^|[;&| ])(godot|love|cargo run|go run|dotnet run|xcrun|python3? [^ ]+\.py|node [^ ]+\.(js|mjs|cjs|ts)|bun [^ ]+\.(js|ts))' \
    || printf '%s' "$cmd" | grep -qiE '(^|[;&| ])((ba|z)?sh +[^ ]+\.sh|\./[^ ;|&]+)' \
    || printf '%s' "$cmd" | grep -qiE 'curl [^;|&]*(localhost|127\.0\.0\.1)'; then
    verified=1
  fi
else
  # MCP tools that exercise or observe a running program count as verification.
  case "$tool" in
    mcp__*run*|mcp__*test*|mcp__*error*|mcp__*screenshot*|mcp__*console*|mcp__*runtime*|mcp__*navigate*|mcp__*computer*|mcp__*play*) verified=1 ;;
  esac
fi

[ "$verified" = 1 ] || exit 0
dir="${VERIFY_LOOP_STATE_DIR:-$HOME/.claude/verify-loop-state}/state"
mkdir -p "$dir"
date +%s > "$dir/$sid.verify"
exit 0
