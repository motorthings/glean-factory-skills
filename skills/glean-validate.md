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
- **Workflow (import)**: has `rootWorkflow` at top level with `schema.steps`. Route to Workflow validation (Sections 2-6 below).
- **Workflow (export)**: has `workflow` at top level with `schema.steps`. Note this to the user -- it needs wrapping for import. Route to Workflow validation.
- **Auto Mode (import)**: has `rootWorkflow` with `schema.autonomousAgentConfig`. Route to Auto Mode validation (Section 7 below).
- **Auto Mode (export)**: has `workflow` with `schema.autonomousAgentConfig`. Route to Auto Mode validation.
- **Auto Mode (plain text)**: input is not valid JSON. Treat as Auto Mode instruction text. Route to Auto Mode validation (Section 7, instruction checks only).
- **Unknown JSON**: valid JSON but no recognized keys. Error: "Unrecognized Glean agent format -- expected rootWorkflow.schema.steps (Workflow) or rootWorkflow.schema.autonomousAgentConfig (Auto Mode)."

Detection order: attempt JSON parse first. If valid JSON, check for known keys. If not valid JSON, treat as instruction text.

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

If `--fix` was specified, also output a list of suggested repairs that can be fed to `/glean-repair-workflow`:

```
### Suggested Repairs
1. [finding description] -- [suggested fix]
2. ...
```

---

### 7. Auto Mode Validation

Run this section when format detection identifies an Auto Mode agent (JSON with `autonomousAgentConfig`) or plain instruction text.

#### 7a. Automated Checklist

**Shared checks (both modes):**
- Naming convention: BETA / LIVE / DRAFT tag present in agent name (if available)
- Data sensitivity: Flag if domain is Legal, HR, or Finance
- No PII or secrets hardcoded in instructions
- No personal references (@-mentions, personal names that should not be in shared instructions)

**Auto Mode-specific checks:**

| Check | Threshold | Severity |
|---|---|---|
| Instruction length | >6K chars | WARN |
| Instruction length | >8K chars | FAIL |
| Dead weight sections | Future features, TODOs, unimplemented hooks | WARN |
| Scope boundaries | No "this agent does NOT..." or equivalent | WARN |
| Decision logic specificity | Vague criteria ("use best judgment" without concrete rules) | WARN |
| Output format defined | No structured output section | WARN |
| Action references | Actions listed but not referenced in instructions | WARN |
| Knowledge source references | Sources listed but not referenced in instructions | WARN |
| Interaction model | No guidance on how to interact with user | INFO |

#### 7b. Qualitative Review

Perform an LLM-driven review of the instruction content:

- **Clarity**: Is the purpose unambiguous? Could someone unfamiliar with the domain understand what this agent does?
- **Decision logic**: Are rules specific enough to produce consistent results across runs, or is there interpretation variance?
- **Interaction model**: Does it define how the agent engages the user (what to ask, when to escalate, what to refuse)?
- **Completeness**: Are there obvious gaps given the stated purpose?
- **Token efficiency**: Is every section earning its place in the instruction budget?

#### 7c. Report Format

```
## Auto Mode Agent Review: [name or "Unnamed"]

### Checklist
[PASS / WARN / FAIL items]

### Instructions Review
[Qualitative findings -- clarity, decision logic, interaction model, completeness, token efficiency]

### Knowledge Sources
[Coverage assessment, or "Not provided"]

### Actions
[Relevance assessment, or "Not provided"]

### Conversation Starters
[Quality check, or "Not provided"]

### LLM Mode / Model
[Appropriateness assessment, or "Not provided"]

### Summary
- Issues: N
- Warnings: N
- Verdict: PASS / PASS WITH WARNINGS / NEEDS REVISION
```
