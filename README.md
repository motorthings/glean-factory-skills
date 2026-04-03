# Glean Factory Skills

Claude Code skills for building, validating, repairing, and extracting Glean agent configurations. Replaces the [Glean Agent Factory](https://github.com/motorthings/glean-agent-factory-app) web app with a CLI-native workflow.

## What This Is

Instead of running a separate Electron/Next.js/FastAPI app to build Glean agents, these skills let you do it conversationally in Claude Code. Hand it a PRD (or build one through interview), and it produces importable Glean agent JSON with full documentation.

## Skills

| Skill | Command | What It Does |
|-------|---------|-------------|
| **glean-discover** | `/glean-discover` | Conversational requirements interview (PuRDy methodology). Produces a PRD. |
| **glean-build** | `/glean-build` | Routes PRD to Workflow Mode (6-phase pipeline -> importable JSON) or Auto Mode (instruction design -> paste-ready build brief). |
| **glean-validate** | `/glean-validate` | Validates Workflow Mode JSON (structural, budget, anti-patterns) or Auto Mode agents (instruction quality, checklist, qualitative review). |
| **glean-repair-workflow** | `/glean-repair-workflow` | Targeted fixes to Workflow Mode agent JSON based on validation findings or manual review. |
| **glean-extract** | `/glean-extract` | Export a live agent's JSON from Glean via Chrome CDP. |

## Usage

These are conversational skills. You don't need to memorize exact commands -- just describe what you want:

```
"I'd like to build a Glean agent from this PRD"          -> /glean-build
"Help me figure out requirements for a new agent"         -> /glean-discover
"Can you check this agent JSON for issues?"               -> /glean-validate
"Fix the variable syntax problems in this agent"          -> /glean-repair-workflow
"Export the Deal Desk agent from Glean"                   -> /glean-extract
```

Or invoke directly with `/glean-build`, `/glean-discover`, etc.

## Typical Workflow

```
1. /glean-discover     Gather requirements, produce a PRD
        |
2. /glean-build        Run 6-phase pipeline -> agent JSON + docs
        |
3. /glean-validate     Check for structural issues
        |
4. /glean-repair-workflow  Fix any findings (Workflow Mode)
        |
5. Import into Glean   Paste JSON in Agent Builder UI
        |
6. /glean-extract      Export live version for version control
```

### Build Pipeline Phases

`/glean-build` runs 6 sequential phases, each feeding the next:

| Phase | Name | What Happens | Gate |
|-------|------|-------------|------|
| 0 | Fitness Check | Problem-solution fit, Glean platform fit, pattern matching | FAIL = stop |
| 1 | Gap Analysis | 12-category gap analysis (incl. mode validation), risk assessment, resolution playbooks | BLOCK = stop |
| 2 | Workflow Design | Architecture pattern selection, step sizing, QA decision | User approval |
| 3 | Instructions | Goal-Return Format-Warnings-Context per step, UUID registry | -- |
| 4 | JSON Generation | Complete agent-config.json + 4 supporting docs | -- |
| 5 | Summary | Build summary, lessons learned | -- |

### Discovery Stages

`/glean-discover` runs a 6-stage Socratic interview:

1. **Problem and Current State** -- what's broken today
2. **Scale and Impact** -- frequency, affected population, cost
3. **Stakeholders and Ownership** -- decision maker, sponsor, detractors
4. **Systems and Data** -- integrations, data flows, constraints
5. **Success Criteria and Scope** -- metrics, MVP, out-of-scope
6. **Risks and Constraints** -- compliance, timeline, prior attempts

Two modes: `--mode triage` (5 min quick assessment) or full discovery (default).

## Setup

### Prerequisites

- [Claude Code](https://claude.ai/code) CLI installed
- This repo cloned to `~/Vault/GitHub/glean-factory-skills/`
- The [Agent Factory app repo](https://github.com/motorthings/glean-agent-factory-app) cloned to `~/Vault/GitHub/glean-agent-factory-app/` (for knowledge docs)

For `/glean-extract` only:
- Chrome with CDP enabled (`--remote-debugging-port=9222`)
- Authenticated Glean session in that Chrome instance
- Python + `websocket-client` (auto-installed via `uv run`)

### Install

```bash
cd ~/Vault/GitHub/glean-factory-skills
./install.sh
```

This creates symlinks from each skill file into `~/.claude/skills/`, where Claude Code picks them up automatically. No restart needed.

### Verify

After install, the skills should appear in Claude Code's skill list. You can check with:

```bash
ls -la ~/.claude/skills/glean-*.md
```

Each should be a symlink pointing back to this repo.

## Knowledge Docs

Skills reference Glean platform knowledge docs at runtime. These live in the Agent Factory app repo:

```
~/Vault/GitHub/glean-agent-factory-app/backend/engine/knowledge/
```

Each skill loads only the docs it needs to minimize context usage:

| Skill / Phase | Docs Loaded |
|--------------|-------------|
| Fitness (Phase 0) | feasibility-rules, connector-registry, platform-reference-slim |
| Gap Analysis (Phase 1) | feasibility-rules, connector-registry, platform-reference-slim |
| Workflow Design (Phase 2) | actions-catalog, connector-registry, platform-reference-slim, prompt-engineering |
| Instructions (Phase 3) | platform-reference (full), prompt-engineering |
| JSON Generation (Phase 4) | actions-catalog, json-schema, platform-reference (full) |
| Summary (Phase 5) | none (uses prior phase outputs) |
| Validate | json-schema, platform-reference (full), tyler-best-practices |
| Repair (Workflow) | json-schema, platform-reference (full), prompt-engineering, actions-catalog |
| Discover | none (interview-driven) |
| Extract | none (CDP script) |

If the knowledge docs aren't available locally, skills still work but with less Glean-specific context for JSON generation and validation.

## Build Output

`/glean-build` produces 5 files in the output directory (default `./glean-build-output/`):

| File | Purpose |
|------|---------|
| `agent-config.json` | Importable Glean agent JSON configuration |
| `architecture-guide.md` | Design rationale, data flow, ASCII diagram, prerequisites |
| `deployment-instructions.md` | Step-by-step import and config guide |
| `test-scenarios.md` | Happy path, edge case, and error handling tests |
| `agent-summary.md` | Executive summary for stakeholders |

## Key Design Decisions

**Why skills instead of a web app?**
- Faster iteration -- no server startup, no UI context switching
- Conversational -- describe what you want in natural language
- Composable -- chain skills together, mix with other Claude Code capabilities
- Version controlled -- skills are markdown files in a git repo

**Why separate knowledge docs?**
- Same docs serve both the web app and these skills
- Phase-specific loading keeps context lean (Phase 0 doesn't need the full JSON schema)
- Knowledge evolves independently of skill logic

**Why symlinks?**
- Single source of truth in this repo
- `~/.claude/skills/` is where Claude Code discovers skills
- Updates to the repo are immediately available without re-running install

## Repo Structure

```
glean-factory-skills/
  README.md          This file
  install.sh         Symlinks skills into ~/.claude/skills/
  .gitignore
  skills/
    glean-build.md       6-phase build pipeline
    glean-validate.md    Structural + budget + anti-pattern validation
    glean-repair-workflow.md  Targeted fix application (Workflow Mode)
    glean-extract.md     CDP-based JSON export from Glean
    glean-discover.md    PuRDy conversational requirements interview
```

## Related Repos

- [glean-agent-factory-app](https://github.com/motorthings/glean-agent-factory-app) -- The original web app (Electron + Next.js + FastAPI). Knowledge docs live here.
- [glean-agent-factory](https://github.com/motorthings/glean-agent-factory) -- The original CLI tool.
