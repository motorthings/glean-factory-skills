# Glean Factory Skills

Claude Code skills for building, validating, repairing, and extracting Glean agent configurations. Replaces the Glean Agent Factory web app with a CLI-native workflow.

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| glean-build | `/glean-build` | 6-phase pipeline: fitness check, gap analysis, workflow design, instructions, JSON generation, summary |
| glean-validate | `/glean-validate` | Structural validation + budget audit + anti-pattern checks on agent JSON |
| glean-repair | `/glean-repair` | Targeted fix application to agent JSON based on specific findings |
| glean-extract | `/glean-extract` | Export agent JSON from Glean via Chrome CDP |
| glean-discover | `/glean-discover` | Conversational PRD interview (requirements gathering) |

## Setup

### Install skills

```bash
# Symlink each skill into ~/.claude/skills/
./install.sh
```

### Knowledge docs

Skills reference Glean knowledge docs at runtime. These live in the Agent Factory app repo:

```
~/Vault/GitHub/glean-agent-factory-app/backend/engine/knowledge/
```

If that repo is not cloned locally, the skills will still work but with reduced context for JSON generation and validation.

## Typical Workflow

1. `/glean-discover` -- gather requirements through conversation, produce a PRD
2. `/glean-build` -- run the 6-phase pipeline against the PRD to produce agent JSON + docs
3. `/glean-validate` -- validate the generated JSON for structural issues
4. `/glean-repair` -- fix any issues found by validation
5. Import JSON into Glean Agent Builder
6. `/glean-extract` -- later, export the live agent for version control or analysis

## Knowledge Doc Mapping

Each skill loads only the knowledge docs it needs:

| Phase | Docs |
|-------|------|
| Fitness (Phase 0) | feasibility-rules, connector-registry, platform-reference-slim |
| Gap Analysis (Phase 1) | feasibility-rules, connector-registry, platform-reference-slim |
| Workflow Design (Phase 2) | actions-catalog, connector-registry, platform-reference-slim, prompt-engineering |
| Instructions (Phase 3) | platform-reference (full), prompt-engineering |
| JSON Generation (Phase 4) | actions-catalog, json-schema, platform-reference (full) |
| Summary (Phase 5) | none (uses prior phase outputs) |
| Validate | json-schema, platform-reference (full) |
| Repair | json-schema, platform-reference (full), prompt-engineering, actions-catalog |
