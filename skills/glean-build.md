---
name: glean-build
description: Build a Glean agent from a PRD. Routes to Workflow Mode (6-phase pipeline producing importable JSON) or Auto Mode (instruction design + paste-ready build brief) based on PRD analysis. Use when user has a PRD or requirements doc and wants to produce a buildable Glean agent.
---

# Glean Agent Builder

Build a complete Glean agent from a PRD (Product Requirements Document). The pipeline detects whether the agent should be built as Workflow Mode (multi-step, deterministic) or Auto Mode (single-instruction, conversational) and routes to the appropriate build path.

**Workflow Mode path:** Phase 0 -> Phase 1 -> Phase 2 -> Phase 3 -> Phase 4 -> Phase 5 (produces importable JSON)
**Auto Mode path:** Phase 0 -> Phase 1 -> Phase 2A -> Phase 3A (produces paste-ready build brief)

## Arguments

The user provides:
- A PRD (pasted, file path, or URL)
- Optional: reference documents (knowledge base docs the agent will use)
- Optional: output directory (default: `./glean-build-output/`)

## Knowledge Docs

Knowledge docs live at `~/Vault/GitHub/glean-agent-factory-app/backend/engine/knowledge/`. Each phase loads only what it needs:

| Phase | Docs to Read |
|-------|-------------|
| 0 - Fitness | feasibility-rules.md, glean-connector-registry.md, glean-platform-reference-slim.md |
| 1 - Gap Analysis | feasibility-rules.md, glean-connector-registry.md, glean-platform-reference-slim.md |
| 2 - Workflow Design | glean-actions-catalog.md, glean-connector-registry.md, glean-platform-reference-slim.md, glean-prompt-engineering.md |
| 3 - Instructions | glean-platform-reference.md, glean-prompt-engineering.md |
| 4 - JSON Generation | glean-actions-catalog.md, glean-json-schema.md, glean-platform-reference.md |
| 2A - Instruction Design | glean-platform-reference-slim.md, glean-prompt-engineering.md |
| 3A - Build Brief | glean-platform-reference-slim.md |
| 5 - Summary | none |

At the start of each phase, read the relevant knowledge docs. Do not read all docs upfront.

Also read `tyler-glean-best-practices.md` once at the start -- it contains critical anti-patterns.

## System Role

You are a Glean Agent Architect. Your job is to take a PRD and produce a complete, buildable Glean agent configuration.

You have deep expertise in:
- Glean's agent platform (triggers, step types, actions, memory, search)
- The JSON configuration schema for Glean agents
- Prompt engineering for agent task instructions
- The Glean connector ecosystem and integration patterns

Key rules:
- Variable syntax: [[variable_name]] for form fields and step references
- 8,000 character limit per step task instructions (target 4,000)
- 4,096 token output limit per action
- Monolithic workflows -- no external agent calls or parallel processes
- Parallel steps: omit stepDependencies on steps that don't need each other's output
- Use manual search mode for deterministic KB retrieval
- For prescriptive workflows: use Think as the synthesis step (deterministic, controllable)
- Plan & Execute ONLY for genuinely exploratory workflows (rare)
- Step type field is "type" (NOT "stepType"). Use "type": "BRANCH"|"TOOL"|"AGENT"
- Instruction field is "instructionTemplate" (NOT "taskInstruction")
- Every step requires "memoryConfig": "ALL_DEPENDENCIES"
- The first step must NOT have a "stepDependencies" field
- Do NOT set "modelOptions.provider" or "modelOptions.model" -- leave "modelOptions": {}

## Pipeline

### Phase 0: Fitness Check

Read knowledge docs for this phase, then evaluate the PRD:

**0. Problem-Solution Fit**
- Does the Problem Statement describe a real, recurring workflow problem?
- Is the proposed agent addressing the root cause, or automating a broken process?
- Rate: ALIGNED / PARTIAL / MISALIGNED

**1. Fitness Assessment** -- rate as:
- **GO** -- PRD is clear, requirements well-defined, Glean can handle this
- **CONDITIONAL_PASS** -- minor clarifications needed but viable
- **FAIL** -- not a good fit for Glean. Explain why and suggest alternatives

Mandatory FAIL conditions (any one is sufficient):
- Required data source has no Glean connector AND no viable workaround
- Core workflow requires storing/caching data outside Glean (stateless platform)
- Use case requires real-time bidirectional sync
- Better solved by process/policy change or non-AI tool
- Problem-solution fit is MISALIGNED

**2. Pattern Match** -- compare PRD against these patterns:
1. Q&A Bot
2. Workflow Agent
3. Scheduled Reporter
4. Approval Workflow
5. Data Sync Agent
6. Alert Monitor
7. Document Generator
8. Conversational Assistant
9. Onboarding/Guided Flow
10. Decision Tree Agent

**3. Mode Signal Scan** -- after the pattern match, evaluate which Glean agent mode fits this PRD:

| Signal | Auto Mode | Workflow Mode |
|--------|-----------|---------------|
| Step structure | Single task or judgment call | Multi-step with defined sequence |
| Branching | No conditional routing needed | Routes based on input classification |
| Write actions | None, or single supplementary action | Write actions at specific points in process |
| Nature of intelligence | Domain expertise + judgment (advisory) | Data orchestration + transformation |
| Output variability | Responses vary based on conversation | Structured, repeatable output format |

Count Auto Mode signals:
- **4-5**: Recommend Auto Mode. State rationale. Ask user: proceed as Auto Mode, or override to Workflow?
- **3**: Ambiguous. Present both options with trade-offs. User decides.
- **0-2**: Proceed as Workflow Mode (no interruption).

If recommending Auto Mode: note that there is no JSON import for Auto Mode. The build output will be a paste-ready brief for the Glean UI.

**4. Requirements Summary** -- extract agent name, trigger type, data sources, output format, complexity estimate

**STOP on FAIL.** If fitness is FAIL, report the result and stop the pipeline. Do not proceed to Phase 1.

Present Phase 0 results to the user and ask: proceed, or address issues first?

---

### Phase 1: Gap Analysis

Read knowledge docs for this phase. Include any reference documents the user provided.

Perform gap analysis across 12 categories, rating each as Critical / High / Medium / Low / None:

1. Data model mismatches
2. Section name accuracy
3. Static vs. generated content
4. File format compatibility
5. Document purpose vs. assumption
6. Integration feasibility
7. Platform readiness
8. Stakeholder confirmations needed
9. Compliance/legal gaps
10. Output action feasibility
11. Problem-solution alignment
12. Mode validation -- Cross-reference Phase 0 mode recommendation against detailed requirements. If Auto Mode recommended: do any requirements need branching, quality gates, multi-step data flow, or >20 actions? If yes, override to Workflow. If Workflow recommended: is every step necessary, or is this a single instruction with good structure? If over-engineered, suggest Auto Mode. If Ambiguous: make final recommendation with rationale.

Gap analysis verdict must include confirmed mode: "proceed as **Auto Mode**" or "proceed as **Workflow Mode**".

For tagged document references (@doc-name): first check if the PRD contains the content inline. If so, it's a label, not an external dependency.

Cross-reference every connector/trigger claim against feasibility-rules.md.

Output format:
- Prerequisites checklist
- Summary table (category | severity | status | description)
- Detailed findings per category
- Stakeholder questions (numbered)
- Resolution playbooks for High/Critical gaps (step-by-step, acceptance criteria, failure mode, effort estimate)
- Overall risk: **proceed** / **proceed with caution** / **block**

**STOP on BLOCK.** If overall risk is "block", present findings to the user and ask whether to continue (with checkbox override) or stop.

Present Phase 1 results to the user and ask: proceed, address gaps first, or override and continue?

---

### Phase 2A: Instruction Design (Auto Mode)

Entered when Phase 1 confirms Auto Mode. Skips Workflow Phases 2-4.

Read knowledge docs: glean-platform-reference-slim.md, glean-prompt-engineering.md

Structure the instruction block using the PRD requirements:

1. **Purpose** (1-3 sentences) -- what the agent does
2. **Decision logic** -- concrete rules, criteria, thresholds (the core of the instruction). Be specific: red-flag examples, classification criteria, scoring rubrics. Vague rules produce inconsistent results.
3. **Interaction model** -- how to engage the user. What to ask, when to escalate, what to refuse.
4. **Output format** -- how responses should be structured. Define sections, ordering, conditional inclusion.
5. **Scope / boundaries** -- what the agent will NOT do.
6. **Operational notes** -- entity names, process references, system-specific details.

**Quality checklist** (run against draft):
- Total instruction length under 6K chars (WARN at 6K, FAIL at 8K)
- No dead weight (future features, TODOs, unimplemented hooks)
- No personal references (@-mentions, individual names)
- Decision logic uses concrete criteria, not vague guidance
- Output format explicitly defined
- Scope boundaries stated
- Interaction model covers: what to ask, when to escalate, what to refuse

Present the full instruction text and checklist results. Wait for user approval before Phase 3A.

---

### Phase 3A: Build Brief (Auto Mode)

Read knowledge docs: glean-platform-reference-slim.md

Generate a paste-ready build brief organized by Glean UI fields:

```
## Build Brief: [Agent Name]

### Instructions
[Full instruction text from Phase 2A -- paste into Glean instructions field]

### Knowledge Sources
[List each doc/folder to add, with rationale]

### Conversation Starters
| Label | Prompt |
|-------|--------|
| [display text] | [full prompt text] |

### Actions
[Which actions to enable, with rationale]

### LLM Mode
[Fast or Thinking] -- [rationale]

### LLM Model
[Model name] -- [rationale]

### Agent Name
[Following naming convention: (BETA v1) Name (Department)]

### Post-Build Checklist
- [ ] Create new Auto Mode agent in Glean
- [ ] Paste instructions
- [ ] Add knowledge sources
- [ ] Enable actions
- [ ] Add conversation starters
- [ ] Set LLM mode and model
- [ ] Set agent name and description
- [ ] Test with 3-5 representative queries
- [ ] Share with beta testers as Viewers
```

Guidelines:
- Knowledge sources: only docs referenced in instructions or essential for the domain
- Actions: only actions the instructions reference or depend on
- LLM mode: Thinking for judgment/analysis, Fast for simple Q&A/retrieval
- LLM model: platform default unless task demands specific model strengths
- Conversation starters: each demonstrates a distinct use case

---

### Phase 2: Workflow Design

Read knowledge docs for this phase.

**Mandatory Complexity Scan (do this BEFORE selecting a pattern):**
1. How many sequential decision stages?
2. How many terminal outcomes (STOP/REVIEW/REJECT)?
3. How many conditional branches?
4. Does any stage require validating user input before proceeding?

Hard rule: 3+ decision stages with terminal outcomes = Decision Tree Pipeline.

**Pattern Selection** (first match wins):
1. 2+ data sources with parallel retrieval -> Cohesive Synthesis Pipeline
2. Write actions -> Cohesive Synthesis Pipeline
3. Quality gating -> Cohesive Synthesis Pipeline
4. Multi-stage decisions with 3+ stages and terminal outcomes -> Decision Tree Pipeline
5. Conditional routing -> Conditional Enterprise Action Framework
6. Dynamic list iteration -> Dynamic Research Engine
7. Single knowledge source, no writes, genuinely exploratory -> Single-step Conversational

State: "Pattern chosen: [name]. Reason: [1-2 sentences]"

**Step Sizing Rules:**
- One step, one job. If you can't describe purpose in one sentence, split it.
- Split when: >5K chars, different tools needed in sequence, different temperatures needed, checkpoint needed, multiple output formats, 2+ parallel searches feed synthesis
- Keep as one step only when: single tool, single intent, under 4K chars, no branching

**Design each step:**

| Step | Name | Type | Purpose | Sentinel | Memory | Dependencies |
|------|------|------|---------|----------|--------|--------------|

Step types: company_search, think, respond, read_document, branch, action, wait_for_user_input, analyze_data, web_search, plan_and_execute (USE SPARINGLY)

**Design constraints:**
- Target 4K chars per instruction (8K hard limit)
- Manual search mode for deterministic retrieval
- Think as final synthesis for prescriptive workflows
- [[field_name]] for form inputs, [[step_uuid]] for step outputs
- Branch steps depend directly on search output, never on intermediate Think
- Web search steps use NO_MEMORY or IMMEDIATE_PREVIOUS memory config

**QA Validation** -- for every agent with 3+ steps, decide whether to include a QA step. Document reasoning either way.

Output:
1. Pattern chosen + rationale
2. Workflow table
3. ASCII flow diagram
4. Data flow description
5. Memory strategy
6. QA step decision
7. Key design decisions and trade-offs

Present to the user for approval before proceeding.

---

### Phase 3: Write Task Instructions

Read knowledge docs for this phase.

**UUID Registry** -- before writing any instructions, generate a UUID for every step:

| Step # | Step Name | UUID |
|--------|-----------|------|

Use these UUIDs in all [[uuid]] references. Never use [[step_1]] positional references. UUIDs: lowercase hex, 8-4-4-4-12 format.

**Instruction Framework** (per step):

**Goal** (1-3 sentences) -- what the step achieves

**Return Format** (most important) -- exact output structure with headings, fields, formats

**Warnings** -- edge cases, things NOT to do, failure modes

**Context** -- [[step_uuid]] for dependencies, [[field_name]] for form inputs, which KB docs to consult

**Rules:**
- Under 4K chars target, 8K absolute max. If draft exceeds 5K, STOP and split.
- NEVER duplicate KB document content in instructions. Reference @doc-name, don't reproduce it.
- Imperative active voice
- Every instruction must specify exact return format
- At least one Warning per step
- [[variable]] syntax (NOT {{variable}})
- Set temperature explicitly: Think = FACTUAL, Respond retrieval = FACTUAL, Respond prose = CREATIVE
- Company search steps MUST include gleanSearchConfig.inclusions.datasourceInstances in toolConfig
- When sensitivity flagged: enforce at BOTH search (folder scoping) and synthesis (NEVER include warning) layers
- Handle sentinel strings explicitly
- Knowledge boundary: "If [item] does not appear in @[doc], treat as UNAVAILABLE. Do not infer."
- Rule citation: cite specific rule for STOP/WARN/BLOCKED verdicts
- Structured conditionals: IF-THEN blocks, not embedded prose
- Response length targets: 200-300 words conversational, 500+ document generation

**Validation step patterns** (when workflow includes input or QA validation):

Input validation Think steps output: STATUS (CLASSIFIED|INSUFFICIENT|CLASSIFIED_WITH_CAVEAT), RESULT, CONFIDENCE_NOTE, CLARIFICATION_NEEDED, REASONING

QA Think steps output: QA_STATUS (PASS|ISSUES_FOUND), CHECKS, VALIDATED_OUTPUT or ISSUES list

Output format per step:
```
=== STEP N: [Step Name] ===
Type: [step_type]
Temperature: [FACTUAL|CREATIVE]

[Full task instruction text]

Character count: [N]/8000
=== END STEP N ===
```

---

### Phase 4: Generate Output Artifacts

Read knowledge docs for this phase.

Generate exactly 5 files:

**File 1: agent-config.json**
Complete Glean agent JSON:
- Top-level: name, description, model, triggerType, rootWorkflow
- rootWorkflow.schema.steps array
- Each step: id (UUID), type (BRANCH/TOOL/AGENT), instructionTemplate, toolConfig or branchConfig
- stepDependencies for context flow
- triggerConfig with fields array (if input_form)

CHAT_MESSAGE trigger format:
```json
"trigger": {
  "type": "CHAT_MESSAGE",
  "config": {
    "chatMessage": {
      "prompts": [
        { "template": "prompt text", "label": "display label" }
      ],
      "slackConfig": { "sharingSettings": {} },
      "scheduleConfig": {}
    }
  }
}
```

Step count validation: JSON steps array MUST match the number of steps from Phase 3.

Input form field rules:
- Field `name`: letters, numbers, dashes, underscores ONLY (no spaces, parens, special chars)
- Field `displayName`: letters, numbers, dashes, underscores, spaces ONLY
- Option `value`: letters, numbers, dashes ONLY. Replace spaces with dashes, drop commas, spell out symbols.
- Known/finite value sets -> SELECT. Free-form -> TEXT. Locations MUST be SELECT.
- No MULTI_SELECT type. Option `label` is always "".

Import-safe tools (auto-bind on import): Think, Company search, Respond. Only these THREE tools auto-bind correctly when JSON is imported. ALL other tools -- including Read document, Create a Google Doc, Plan and execute, and every action pack tool -- appear as "Select step" with a warning triangle after import and require manual configuration.

Branch steps do not use toolConfig and import correctly. Branch steps need descriptive labels on the step itself, each conditional target, and the default target.

Sticky notes (REQUIRED for EVERY step that is not Think, Company search, or Respond):

This is critical. Without sticky notes, the builder has no way to know which tool to select for "Select step" steps after import. Steps 1-6 showing as blank "Select step" boxes is a build failure.

Rules:
- EVERY step whose tool is NOT Think, Company search, or Respond MUST have a sticky note. This includes Read document steps.
- backgroundColor: "#FFE0B2" (orange)
- Each sticky note content MUST include ALL of:
  1. Which tool to select: "Select '[exact tool name]' from the action dropdown"
  2. Any configuration needed (folder IDs, document URLs, field mappings)
  3. Recommended model: suggest a model for the step based on its needs:
     - Retrieval/read steps (Read document, Company search): "Model: default (no override needed) -- simple retrieval"
     - Generation/synthesis steps (Think for content creation): "Model: Claude Sonnet 4.6 (VERTEX_AI) -- complex generation needs strongest model"
     - QA/validation steps (Think for checking): "Model: Claude Sonnet 4.6 (VERTEX_AI) -- accuracy critical"
     - Delivery steps (Respond): "Model: default -- straightforward response assembly"
     - Action steps (Create a Google Doc, etc.): "Model: default -- action execution"
- Format: "MANUAL CONFIG REQUIRED -- Step N ([step label]): Select '[tool name]' from the action dropdown. [Config details]. [Model recommendation]."
- boundingBox positioning -- place each note near its step on the canvas:
  - Glean lays out PARALLEL steps (no dependencies between them) in a HORIZONTAL row, each ~250px apart starting at x=10
  - Glean lays out SEQUENTIAL steps (with dependencies) in a VERTICAL chain below
  - For parallel steps: place each note BELOW its step. Use the same x offset as the step (step 1 at x=10, step 2 at x=260, step 3 at x=510, etc.), y = row_y + 150 (below the step card). Width=240, height=120.
  - For sequential steps: place each note to the RIGHT of its step. x = step_x + 250, same y as the step. Width=300, height=80.
  - Informational notes (green/blue): place in clear space near the top or beside the relevant step
- Every non-auto-binding step gets exactly one matching sticky note

After generating the JSON, do a FINAL VERIFICATION:
1. Count all steps that use a tool other than Think, Company search, or Respond
2. Count all sticky notes
3. These numbers MUST match. If they don't, add the missing sticky notes before outputting.

Example sticky note for a Read document step:
```json
{"backgroundColor":"#FFE0B2","content":"MANUAL CONFIG REQUIRED -- Step 2 (Load Hiring Package Template)\\: Select 'Read document' from the action dropdown. Set document URL to the Hiring Package Template Google Doc. Model: default -- simple retrieval.","boundingBox":{"x":350,"y":250,"width":320,"height":100}}
```

Example sticky note for a Create a Google Doc step:
```json
{"backgroundColor":"#FFE0B2","content":"MANUAL CONFIG REQUIRED -- Step 9 (Create Google Doc)\\: Select 'Create a Google Doc' from the action dropdown. Set Folder ID to 1GD61BftwTKkjffjPJezMg1j05tOqcE12. Model: default -- action execution.","boundingBox":{"x":350,"y":1300,"width":320,"height":100}}
```

**File 2: architecture-guide.md** -- overview, data access, KB setup, workflow detail, ASCII diagram, decisions, prerequisites, risks, build sequence

**File 3: deployment-instructions.md** -- step-by-step import and config instructions

**File 4: test-scenarios.md** -- happy path, edge cases, error handling, expected outputs

**File 5: agent-summary.md** -- executive summary for stakeholders

Write each file to the output directory using the file names above.

---

### Phase 5: Summary

Generate build summary:
- Agent name and trigger type
- Step count and types
- Architecture pattern
- Key design decisions
- Prerequisites needing manual setup
- Estimated build effort (hours)
- Risk level and top risks

Capture lessons learned:
- What worked well
- What was tricky
- Platform limitations
- Patterns/anti-patterns discovered
- Recommendations for similar agents

Present the summary to the user.

---

## Output

All output files are written to the output directory (default: `./glean-build-output/`):

```
glean-build-output/
  agent-config.json
  architecture-guide.md
  deployment-instructions.md
  test-scenarios.md
  agent-summary.md
```

## Post-Build

**Workflow Mode:** After the pipeline completes, suggest:
1. Run `/glean-validate` on the generated agent-config.json
2. Import into Glean Agent Builder
3. Run `/glean-extract` after manual adjustments to capture the live version

**Auto Mode:** After the pipeline completes, suggest:
1. Follow the Post-Build Checklist in the build brief
2. After building in the Glean UI, test with the conversation starters
3. Run `/glean-validate` with the instruction text to verify quality
4. Share with beta testers as Viewers
