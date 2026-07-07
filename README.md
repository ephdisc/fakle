# verify-loop — Claude Code plugin

Makes Opus (or any Claude Code model) follow a **verify-before-finish** routine: it tracks the code you edit, watches for tests/runs that actually exercise those edits, and blocks ending a turn on changes that were never verified — so Claude doesn't quietly hand verification back to you.

This repository is a self-contained Claude Code **marketplace** hosting a single plugin, `verify-loop`.

## Install (one command)

Point Claude Code at this marketplace, then install the plugin:

**From GitHub:**

```bash
claude plugin marketplace add ephdisc/fakle && claude plugin install verify-loop@verify-loop
```

**From a local clone / shared drive:**

```bash
claude plugin marketplace add /path/to/this/repo && claude plugin install verify-loop@verify-loop
```

Restart Claude Code (or start a new session) and the hooks are live.

## Enable / disable

Standard plugin controls — no reinstall needed:

```bash
claude plugin disable verify-loop   # pause the routine
claude plugin enable  verify-loop   # resume it
```

Or run `/plugin` inside Claude Code for the interactive manager.

## Update

```bash
claude plugin update verify-loop
```

## What's inside

```
.claude-plugin/marketplace.json      # marketplace manifest (this repo)
plugins/verify-loop/                  # the plugin
  .claude-plugin/plugin.json          # plugin manifest
  hooks/hooks.json                    # hook wiring
  hooks/*.sh                          # the four hook scripts
  README.md                           # plugin details & tuning
```

See [`plugins/verify-loop/README.md`](plugins/verify-loop/README.md) for how each hook behaves and how to tune it.

## Requirements

`jq` and `bash` must be on `PATH` (both standard on macOS/Linux dev machines).
