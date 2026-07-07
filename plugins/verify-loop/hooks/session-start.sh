#!/bin/bash
# verify-loop: SessionStart hook.
# 1. Resets this session's verify-loop state and prunes old state files.
# 2. Takes an MCP-server inventory (user + project scope), diffs it against
#    the last session's snapshot for this directory, and injects the result
#    as context so the model knows what tools appeared or left.
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')

dir="${VERIFY_LOOP_STATE_DIR:-$HOME/.claude/verify-loop-state}/state"
mkdir -p "$dir"
[ -n "$sid" ] && rm -f "$dir/$sid".*
find "$dir" -type f -mtime +7 -delete 2>/dev/null

# Gather configured MCP servers: user scope, per-project scope, repo .mcp.json
current=$(
  {
    jq -r '.mcpServers // {} | keys[]' "$HOME/.claude.json" 2>/dev/null
    jq -r --arg p "$PWD" '.projects[$p].mcpServers // {} | keys[]' "$HOME/.claude.json" 2>/dev/null
    jq -r '.mcpServers // {} | keys[]' ./.mcp.json 2>/dev/null
  } | sort -u
)

# Per-project snapshot so different repos don't pollute each other's diff
key=$(printf '%s' "$PWD" | shasum 2>/dev/null | cut -c1-12)
snap="$dir/../mcp-snapshot-${key:-global}"
prev=$(cat "$snap" 2>/dev/null)
printf '%s\n' "$current" > "$snap"

added=$(comm -13 <(printf '%s\n' "$prev") <(printf '%s\n' "$current") | grep -v '^$' | paste -sd', ' -)
removed=$(comm -23 <(printf '%s\n' "$prev") <(printf '%s\n' "$current") | grep -v '^$' | paste -sd', ' -)
list=$(printf '%s\n' "$current" | grep -v '^$' | paste -sd', ' -)

ctx="[verify-loop] MCP servers configured for this project: ${list:-none}."
[ -n "$added" ] && ctx="$ctx Newly added since the last session here: $added - consider whether they help the current task."
[ -n "$removed" ] && ctx="$ctx No longer configured: $removed - do not rely on their tools."
ctx="$ctx If a task would be materially easier or more reliable with a tool you do not have (an MCP server, a CLI), say so and give the exact install command (e.g. 'claude mcp add ...') instead of silently working around it."

jq -cn --arg ctx "$ctx" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
exit 0
