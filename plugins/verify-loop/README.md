# verify-loop

A Claude Code plugin that nudges Claude to **verify its own work** before finishing a turn, instead of silently handing verification back to you.

## What it does

The plugin installs four hooks:

| Hook | Event | Behavior |
| --- | --- | --- |
| `session-start.sh` | `SessionStart` | Resets per-session state and injects an inventory of configured MCP servers, flagging any that appeared or disappeared since the last session in this directory. |
| `track-edit.sh` | `PostToolUse` (Edit/Write/MultiEdit/NotebookEdit) | Marks the session "dirty" when code is edited. Docs (`*.md`, `*.txt`, …), `~/.claude/**`, temp dirs, and `CLAUDE.md`/settings are ignored. |
| `track-verify.sh` | `PostToolUse` (Bash, `mcp__*`) | Records a "verification event" when a command actually exercises code — test runners, running the app/scene/server, hitting `localhost`, or MCP tools that run/inspect a live program. |
| `stop-gate.sh` | `Stop` | If code was edited but nothing exercised it since the last edit, blocks the turn once with a reminder to verify. A new edit re-arms it; it never loops forever. |

## State

State lives in `~/.claude/verify-loop-state/` by default (per-session flags plus a per-directory MCP snapshot). Override with the `VERIFY_LOOP_STATE_DIR` environment variable. State is not stored inside the plugin directory, so it survives plugin updates.

## Enable / disable

Managed through the normal plugin interface:

```
/plugin                              # interactive manager
claude plugin disable verify-loop    # turn off
claude plugin enable  verify-loop    # turn back on
```

## Tuning

Edit the `grep` patterns in `track-verify.sh` to teach the plugin which commands count as "verification" for your stack, or the `case` globs in `track-edit.sh` to change which files require verification.

## Requirements

- `jq` (used by every hook to parse hook input)
- `bash`
