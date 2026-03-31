---
name: glean-validate
description: Validate a Glean agent JSON configuration for structural issues, instruction budget violations, and anti-patterns. Use when user has a Glean agent JSON file to check before import.
---

# Glean Agent Validator

Validate a Glean agent JSON configuration for structural correctness, instruction budget compliance, and common anti-patterns.

## Arguments

The user provides:
- A JSON file path (e.g., `./agent-config.json` or `~/agents/my-agent.glean.json`)
- Optional: `--fix` flag to auto-generate repair suggestions

## Knowledge Docs

Read these at the start of validation:
- `~/Vault/GitHub/glean-agent-factory-app/backend/engine/knowledge/glean-json-schema.md`
- `~/Vault/GitHub/glean-agent-factory-app/backend/engine/knowledge/glean-platform-reference.md`
- `~/Vault/GitHub/glean-agent-factory-app/backend/engine/knowledge/tyler-glean-best-practices.md`

## Workflow

### 1. Load and Parse JSON

Read the JSON file. If it fails to parse, report the JSON syntax error with line number and stop.

Detect format:
- **Import format**: has `rootWorkflow` at top level. Steps at `rootWorkflow.schema.steps`.
- **Export format**: has `workflow` at top level with `schema.steps`. Note this to the user -- it needs wrapping for import.

### 2. Structural Validation

Check every step for:

**Required fields:**
- `id` -- must be present, must be a valid UUID, must be unique across all steps
- `type` -- must be one of: BRANCH, TOOL, AGENT (uppercase). Flag if `stepType` is used instead of `type`.
- `instructionTemplate` -- must be present for TOOL and AGENT steps
- `memoryConfig` -- must be present, should be "ALL_DEPENDENCIES"

**Type-specific config:**
- BRANCH steps must have `branchConfig`
- TOOL and AGENT steps must have `toolConfig`

**Dependency integrity:**
- Every ID in `stepDependencies` must reference an existing step ID
- First step must NOT have `stepDependencies`
- No circular dependencies

**Variable syntax:**
- Flag any `{{variable}}` syntax -- must be `[[variable]]`
- Check that [[step_uuid]] references in instructions match actual step IDs in the config

**Top-level structure:**
- `rootWorkflow` (or `workflow` for export format)
- `rootWorkflow.schema.steps` must be a non-empty array
- Trigger config present and matches stated trigger type

### 3. Instruction Budget Audit

For every step with an `instructionTemplate`:

| Threshold | Status |
|-----------|--------|
| <= 4,000 chars | PASS |
| 4,001 - 6,000 chars | WARN -- approaching limit |
| 6,001 - 8,000 chars | CRITICAL -- near hard limit, likely overloaded |
| > 8,000 chars | FAIL -- exceeds Glean hard limit |

Report: step label, character count, status, and if WARN/CRITICAL/FAIL, a suggestion (split the step, extract KB content to a doc reference, remove duplicated content).

### 4. Anti-Pattern Checks

Check for these known issues:

**Architecture anti-patterns (from Tyler's best practices):**
- Plan & Execute used for prescriptive workflows (known inputs, defined outputs) -- should be Think
- Think step inserted between a search and its dependent branch (branch should depend directly on search)
- TEXT field type used for constrained value sets (locations, departments) -- should be SELECT
- No memory config on web search steps (should be NO_MEMORY or IMMEDIATE_PREVIOUS)

**JSON field anti-patterns:**
- `"stepType"` instead of `"type"` (breaks import)
- `"taskInstruction"` or `"instruction"` instead of `"instructionTemplate"`
- `"id"` in toolConfig instead of `"name"` (wrong tool identifier field)
- Wrong tool names: "Glean Search" (should be "Company search"), "Glean Document Reader" (should be "Read document"), "User Activity Retrieve" (should be "Read personal activity")
- `modelOptions.provider` or `modelOptions.model` set (should be empty `{}`)

**CHAT_MESSAGE trigger anti-patterns:**
- `prompts` as plain strings instead of `{template, label}` objects
- `sharingSettings` as sibling to `slackConfig` instead of nested inside
- `scheduleConfig` outside `chatMessage`
- `instanceChannels` or `accessType` present (not valid)

**Input form anti-patterns:**
- Spaces in field `name`
- Parentheses or special chars in `name` or `displayName`
- Spaces, commas, or special chars in option `value`
- Missing `options` array on SELECT fields
- `options` array on TEXT fields

**Step design anti-patterns:**
- Single TOOL step with >3K chars of conditional logic (likely collapsed decision tree)
- KB document content duplicated in instructions (instruction references @doc but also reproduces its content)
- Missing sentinel string handling in steps that receive search output

### 5. Import Readiness Check

For each step, classify the tool:
- **Auto-imports**: Think, Company search, Read document, Respond
- **Manual config needed**: everything else

Count manual-config steps. If any exist, check for corresponding sticky notes in `rootWorkflow.notes[]`. Report missing sticky notes.

### 6. Report

Output a structured report:

```
## Validation Report: [filename]

**Format**: Import / Export
**Steps**: N
**Trigger**: [type]

### Structural Issues
[numbered list, or "None found"]

### Budget Audit
| Step | Label | Chars | Status |
|------|-------|-------|--------|
| 1 | ... | 2,340 | PASS |

### Anti-Pattern Findings
[numbered list with severity: ERROR / WARNING / INFO]

### Import Readiness
- Auto-import steps: N
- Manual-config steps: N [list which ones]
- Missing sticky notes: N [list which ones]

### Summary
- Total errors: N
- Total warnings: N
- Verdict: PASS / PASS WITH WARNINGS / FAIL
```

If `--fix` was specified, also output a list of suggested repairs that can be fed to `/glean-repair`:

```
### Suggested Repairs
1. [finding description] -- [suggested fix]
2. ...
```
