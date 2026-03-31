---
name: glean-extract
description: Extract a Glean agent's workflow JSON automatically via Chrome CDP. Use when user provides a Glean agent URL or asks to extract/export an agent's JSON.
---

# Glean Agent JSON Extractor

Extract a Glean agent's workflow JSON by connecting to an authenticated Chrome session via CDP.

## Arguments

The user provides a Glean agent URL or agent ID. Examples:
- `https://app.glean.com/chat/agents/d3dd6cb6be334ffe9a63a2fb22ebf44b/edit`
- `d3dd6cb6be334ffe9a63a2fb22ebf44b`

The user may also provide an output path. Default: `<agent_id>.glean.json` in the current working directory.

## Workflow

### 1. Check CDP connectivity

First, always show the user this message so they know the prerequisites:

> This requires Chrome running with CDP enabled. If it's not already running, quit Chrome completely and relaunch with:
>
> ```
> /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 --user-data-dir="$HOME/.chrome-cdp" '--remote-allow-origins=*'
> ```
>
> You must be logged into Glean in that Chrome session. Open `https://app.glean.com` and log in.
> The agent edit page should be open: `https://app.glean.com/chat/agents/<id>/edit`

Then check connectivity:

```bash
curl -s http://localhost:9222/json/version | head -3
```

If this fails, wait for the user to launch Chrome and confirm before proceeding.

### 2. Run the extraction script

```bash
uv run --with websocket-client python3 ~/Vault/contentful/glean/extract-glean-agent.py "<url_or_agent_id>" -o "<output_path>"
```

The script will:
- Find the Glean tab via CDP
- Reload the page to trigger the `getworkflow` API call
- Intercept the response via CDP Network domain
- Save the workflow JSON to the output path
- Print agent name, step count, and file path

### 3. Verify and report

After extraction:
1. Read the output JSON file
2. Report: agent name, number of steps, step labels, output file path
3. Offer to run `/glean-validate` on the extracted JSON
4. Note: extracted JSON is **export format** (has `workflow`, not `rootWorkflow`). To import elsewhere, wrap: `{"rootWorkflow": <workflow>}`

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| curl to 9222 fails | Chrome not running with CDP | Quit Chrome, relaunch with flags above |
| No Glean tab found | No Glean page open in CDP Chrome | Open app.glean.com and log in |
| getworkflow not captured | Page didn't trigger API call | Open the agent edit page manually, then retry |
| Handshake 403 | Missing --remote-allow-origins flag | Relaunch Chrome with `'--remote-allow-origins=*'` |

## Important Notes

- Chrome MUST be launched with `--user-data-dir="$HOME/.chrome-cdp"` (enterprise Chrome blocks CDP on default profile)
- Chrome MUST be launched with `'--remote-allow-origins=*'` (single-quoted to prevent zsh glob expansion)
- The existing Chrome must be fully quit first (Cmd+Q) before relaunching
- Output is **export format** (`workflow` object, not `rootWorkflow` import wrapper)
- Script location: `~/Vault/contentful/glean/extract-glean-agent.py`
- Dependency: `websocket-client` (installed automatically via `uv run --with`)
