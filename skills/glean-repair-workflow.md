---
name: glean-repair-workflow
description: Apply targeted fixes to a Glean Workflow Mode agent JSON configuration based on specific findings. Use after /glean-validate identifies Workflow Mode issues, or when user has a specific fix to apply. For Auto Mode agents, edit instructions directly in the Glean UI.
---

# Glean Workflow Agent Repair

Apply targeted fixes to a Glean agent JSON configuration. Fixes exactly what is specified -- does not refactor unrelated parts.

## Arguments

The user provides:
- A JSON file path to the agent config
- One or more findings to fix (from `/glean-validate` output, manual review, or user description)
- Optional: `--all` to fix all findings from a validation report

## Knowledge Docs

Read these at the start:
- `~/Vault/GitHub/glean-agent-factory-app/backend/engine/knowledge/glean-json-schema.md`
- `~/Vault/GitHub/glean-agent-factory-app/backend/engine/knowledge/glean-platform-reference.md`
- `~/Vault/GitHub/glean-agent-factory-app/backend/engine/knowledge/glean-prompt-engineering.md`
- `~/Vault/GitHub/glean-agent-factory-app/backend/engine/knowledge/glean-actions-catalog.md`

## Repair Mode Rules

You are operating in REPAIR mode. Rules:

1. **Fix exactly what the finding describes.** Do not refactor unrelated parts.
2. **Preserve existing structure** -- step IDs, labels, dependencies stay the same unless the finding specifically requires changing them.
3. **Instruction rewrites** use the Goal-Return Format-Warnings-Context framework:
   - Goal: 1-3 sentences on what the step achieves
   - Return Format: exact output structure (most important)
   - Warnings: edge cases and don'ts
   - Context: [[step_uuid]] for dependencies, [[field_name]] for form inputs
4. **New steps** get a fresh UUID and correct stepDependencies wiring.
5. **Removed steps** also clean up any stepDependencies that reference them.
6. **For structural fixes** (field renames, tool names, trigger config, memoryConfig), output the patched JSON directly. **For instruction template rewrites**, use the Python patch pattern (see Common Repair Patterns) — never embed long instruction text inside a JSON string in your output. JSON-escaping 5k+ char strings manually is unreliable and is the primary cause of "Expecting ',' delimiter" parse failures.
7. **Variable syntax** is [[variable_name]], never {{variable}}.
8. **Step type field** is "type" (BRANCH, TOOL, AGENT).
9. **Every step** must have "memoryConfig": "ALL_DEPENDENCIES".

## Workflow

### 1. Load the Agent JSON

Read the JSON file. Detect import vs export format.

### 2. Understand the Findings

For each finding, classify the repair type:

| Repair Type | Examples | Approach |
|------------|---------|----------|
| Field rename | stepType -> type, id -> name in toolConfig | Direct field replacement |
| Value fix | Wrong tool names, bad variable syntax | String replacement |
| Structural | Missing memoryConfig, missing branchConfig | Add missing fields |
| Instruction rewrite | Step overloaded, KB content duplicated | Rewrite using Goal-Return-Warnings-Context |
| Step split | Single step doing too much | Create new steps, rewire dependencies |
| Step add | Missing QA step, missing clarification handler | Generate new step with UUID |
| Step remove | Unnecessary intermediate step | Remove and clean up references |
| Trigger fix | CHAT_MESSAGE format issues | Restructure trigger config |
| Field fix | Input form name/value violations | Clean field names and option values |
| Sticky note | Missing manual-config notes | Add notes to rootWorkflow.notes[] |

### 3. Apply Fixes

For each finding:
1. Show what will change (before/after for the specific section)
2. Apply the fix to the in-memory JSON
3. Verify the fix doesn't break dependencies or references

### 4. Validate the Result

After all fixes are applied, run the same checks as `/glean-validate`:
- Structural integrity
- Dependency references valid
- Variable syntax correct
- Budget compliance

Report any remaining issues.

### 5. Write the Output

Write the repaired JSON to the same file path (overwriting) or to a new path if the user specifies one.

Output a changelog:

```
## Repair Changelog

### Instruction Changes
1. Step N ([label]): [what changed and why]

### Structural Changes
1. [field/step change description]

### Knowledge Base Recommendations
- [any KB docs that should be created or updated based on the repairs]

### Remaining Issues
- [any issues that could not be auto-fixed]
```

## Common Repair Patterns

### Fix tool name in toolConfig
```json
// Before
"toolConfig": { "id": "Glean Search" }
// After
"toolConfig": { "name": "Company search" }
```

Tool name mapping:
- "Glean Search" -> "Company search"
- "Glean Document Reader" -> "Read document"
- "User Activity Retrieve" -> "Read personal activity"

### Fix CHAT_MESSAGE trigger
```json
// Before (broken)
"config": {
  "chatMessage": { "prompts": ["prompt text"] },
  "sharingSettings": {},
  "scheduleConfig": {}
}
// After (correct)
"config": {
  "chatMessage": {
    "prompts": [{ "template": "prompt text", "label": "display label" }],
    "slackConfig": { "sharingSettings": {} },
    "scheduleConfig": {}
  }
}
```

### Fix field names for input forms
Replace spaces with underscores in `name`. Drop parentheses and special chars. Replace spaces with dashes in option `value`. Spell out symbols.

### Instruction template patch (prevents JSON parse failures)

When rewriting an `instructionTemplate` field, never embed the new text directly inside a JSON string in your output. Python handles escaping correctly; Claude output does not at lengths above ~2K chars.

1. Write the new instruction text as a plain fenced code block in your response.
2. Save it to a temp file using the Write tool: `/tmp/new_instruction.txt`
3. Run the Python patch via Bash:

```python
import json

with open('/tmp/new_instruction.txt', 'r') as f:
    new_text = f.read()

with open('<path-to-agent.json>', 'r') as f:
    data = json.load(f)

for step in data['rootWorkflow']['schema']['steps']:
    if step['id'] == '<step-id>':
        step['instructionTemplate'] = new_text
        break

with open('<path-to-agent.json>', 'w') as f:
    json.dump(data, f, indent=4, ensure_ascii=False)

print(f"Patched. Length: {len(new_text)}")
```

Verify the output parses cleanly with `python3 -c "import json; json.load(open('<path>'))"` before reporting success.

### Split overloaded step
When a step exceeds 5K chars or contains multiple responsibilities:
1. Identify the distinct jobs in the instruction
2. Create new step(s) with fresh UUIDs
3. Move relevant instruction sections to each new step
4. Wire stepDependencies: new steps depend on the original's dependencies, downstream steps depend on the new steps
5. Update any [[uuid]] references in other steps
