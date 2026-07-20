# AI Delivery Workflow Template

An AI-powered delivery workflow for engineering teams. Once set up, Claude Code acts as a team of specialized agents — a PM (Alice), an orchestrator, an engineer (Dave), a researcher (Bob), and a payload analyst (Erin) — that collaborate to take a feature from idea to shipped code with full documentation.

---

## Step 1 — Copy the template into your repo

Copy the `af-delivery-workflow-template/` folder to the **root** of your project repository:

```
your-repo/
└── af-delivery-workflow-template/   ← copy this entire folder here
```

---

## Step 2 — Run the setup wizard in Claude Code

Open **Claude Code** in your repo and paste the prompt below into the chat. The wizard will:

1. Explore your codebase and confirm what it found (language, test commands, release process)
2. Check whether workflow files already exist
3. Generate all skill and command files, filled with your project's details
4. Delete the `af-delivery-workflow-template/` folder when done

```
I've copied the af-delivery-workflow-template/ folder into this repo.
The template files are:

  af-delivery-workflow-template/CLAUDE.md.template
  af-delivery-workflow-template/WORKFLOW.md.template
  af-delivery-workflow-template/commands/af-ship.md
  af-delivery-workflow-template/commands/af-ship-from-prd.md
  af-delivery-workflow-template/commands/af-ship-from-tech-design.md
  af-delivery-workflow-template/commands/af-quiz-me.md
  af-delivery-workflow-template/templates/af-tech-quiz-template.html
  af-delivery-workflow-template/skills/af-ship-orch.template.md
  af-delivery-workflow-template/skills/alice-pm.template.md
  af-delivery-workflow-template/skills/dave-engineer.template.md
  af-delivery-workflow-template/skills/bob-researcher.template.md
  af-delivery-workflow-template/skills/erin-domain-analyst.template.md
  af-delivery-workflow-template/prompts/generate-feature-catalog.template.md
  af-delivery-workflow-template/prompts/generate-issue-cases.template.md

Please set up the workflow for this repo by doing the following:

**Step 1 — Explore the repo**
Read the codebase, existing docs, README, CI config, and any build files.
Determine:
- The full project/repo name
- The short domain name (e.g. ios, android, backend, frontend)
- The tech stack (languages, frameworks, build tools)
- How to run the test suite
- How releases are cut and published
- Where feature docs live (or suggest docs/features/)
- Where research docs live (or suggest docs/researches/)
- Where issue cases live (or suggest docs/issue-cases/)
- What counts as a maintenance task (no Alice review needed)

Present your findings and wait for my confirmation before continuing.

**Step 2 — Check for existing workflow files**
Before writing anything, check whether these files already exist:
  CLAUDE.md
  .claude/WORKFLOW.md
  .claude/commands/af-ship.md
  .claude/commands/af-ship-from-prd.md
  .claude/commands/af-ship-from-tech-design.md
  .claude/commands/af-quiz-me.md
  templates/af-tech-quiz-template.html
  .claude/skills/*/SKILL.md
  .claude/prompts/*.md

Report what you find:
- List every file that already exists
- List every file that is new (does not exist yet)

Wait for my confirmation before continuing.

**Step 3 — Generate the new files**
Using the domain name from Step 1 and the filled-in placeholders, generate
all workflow files. Apply this rule for each target path:

- If the file does NOT exist → write it directly at the target path
- If the file ALREADY EXISTS → write the new version alongside it with a
  `.new` suffix (e.g. CLAUDE.md.new, SKILL.md.new)

Target paths:
  af-delivery-workflow-template/CLAUDE.md.template                        → CLAUDE.md (or CLAUDE.md.new)
  af-delivery-workflow-template/WORKFLOW.md.template                      → .claude/WORKFLOW.md (or WORKFLOW.md.new)
  af-delivery-workflow-template/commands/af-ship.md                       → .claude/commands/af-ship.md (copy as-is, no placeholders)
  af-delivery-workflow-template/commands/af-ship-from-prd.md              → .claude/commands/af-ship-from-prd.md (copy as-is)
  af-delivery-workflow-template/commands/af-ship-from-tech-design.md      → .claude/commands/af-ship-from-tech-design.md (copy as-is)
  af-delivery-workflow-template/commands/af-quiz-me.md                  → .claude/commands/af-quiz-me.md (copy as-is)
  af-delivery-workflow-template/templates/af-tech-quiz-template.html      → templates/af-tech-quiz-template.html (copy as-is)
  af-delivery-workflow-template/skills/af-ship-orch.template.md           → .claude/skills/af-ship-orch/SKILL.md (or SKILL.md.new)
  af-delivery-workflow-template/skills/alice-pm.template.md               → .claude/skills/alice-pm/SKILL.md (or SKILL.md.new)
  af-delivery-workflow-template/skills/dave-engineer.template.md          → .claude/skills/dave-<domain>-engineer/SKILL.md (or SKILL.md.new)
  af-delivery-workflow-template/skills/bob-researcher.template.md         → .claude/skills/bob-<domain>-researcher/SKILL.md (or SKILL.md.new)
  af-delivery-workflow-template/skills/erin-domain-analyst.template.md    → .claude/skills/erin-<domain>-analyst/SKILL.md (or SKILL.md.new)
  af-delivery-workflow-template/prompts/generate-feature-catalog.template.md → .claude/prompts/generate-feature-catalog.md (or .md.new)
  af-delivery-workflow-template/prompts/generate-issue-cases.template.md  → .claude/prompts/generate-issue-cases.md (or .md.new)

Also update the `name:` frontmatter field in each SKILL.md to include the domain
(e.g. `name: dave-ios-engineer`). The af-ship-orch and alice-pm skill names do NOT
include the domain — copy them verbatim.

Then delete the af-delivery-workflow-template/ folder.

Add `output.af-quiz-me/` to the repo's `.gitignore` (the /af-quiz-me command writes generated quiz files there).

**Step 4 — Fill in all {{PLACEHOLDER}} tokens**
Using the context from Step 1, replace every {{PLACEHOLDER}} in every generated file.

The placeholders are:
  {{REPO_NAME}}            — full project name
  {{DOMAIN}}               — short domain name
  {{TECH_STACK}}           — languages, frameworks, build tools
  {{TEST_COMMANDS}}        — command(s) to run the test suite
  {{RELEASE_PROCESS}}      — how releases are cut and published
  {{FEATURE_DOC_PREFIX}}   — path to feature docs
  {{RESEARCH_PATH}}        — path to research docs
  {{MAINTENANCE_TASKS}}    — what counts as maintenance
  {{ALICE_PROFILE_NOTES}}  — domain-specific release/PRD notes for Alice
  {{DAVE_PROFILE_NOTES}}   — domain-specific engineering conventions for Dave
  {{BOB_PROFILE_NOTES}}    — domain-specific research sources for Bob
  {{ERIN_PROFILE_NOTES}}   — domain-specific payload/schema conventions for Erin
  {{PROJECT_CONTEXT}}      — one-sentence project description
  {{LANGUAGES}}            — primary language(s)
  {{NOTION_DB_URL}}        — Notion DB URL (leave blank if none)
  {{NOTION_KEYWORDS}}      — keywords to filter Notion pages (leave blank if none)
  {{JIRA_PROJECT_KEY}}     — Jira project key (leave blank — defaults to DELIVERY)

**Step 5 — Show the delta for existing files**
For every file where a .new version was generated alongside an existing one,
show a diff between the old and the new:

  === CLAUDE.md ===
  --- existing
  +++ new
  [unified diff]

For CLAUDE.md specifically, also check whether the existing file contains
these two required sections. Flag any that are missing:

  ✅/❌  ## Maintenance bypass   (required — Dave bypass list for maintenance tasks)
  ✅/❌  ## Output contract      (required — defines what every feature deliverable must include)

If any are missing, recommend appending them from CLAUDE.md.new rather than
doing a full replace, so existing repo-specific content is preserved.

After showing all diffs and the CLAUDE.md section audit, ask:
"Which files should I replace, merge, or skip?"
Wait for my instructions before making any further changes.
```

---

## Step 3 — Build the feature catalog

Open `.claude/prompts/generate-feature-catalog.md`, copy its full contents, and paste into Claude Code.

This builds `docs/features/` — a catalog of every feature in the codebase with:
- **Business Purpose** — what the product loses if the feature is removed (enriched from Notion if connected)
- **Call Chain** — from public entry point to leaf implementation
- **Dependency Diagrams** — runtime flow, initialization flow, and a full dependency table
- **Jira enrichment** — strategic "why" from Epics and Known Limitations from Bug tickets

The prompt walks you through each phase with a live progress view and pauses for your review at key points. You will be asked for a Notion database URL and Jira project key during the run — have them ready if you want enriched Business Purpose sections.

---

## Step 4 — Build the issue case bank

Open `.claude/prompts/generate-issue-cases.md`, copy its full contents, and paste into Claude Code.

This builds `docs/issue-cases/` — an engineering scar book mined from the full git history:
- **IC-NNN-*.md** — one file per real bug: what happened, root cause, fix, and takeaway
- **GUARDRAILS.md** — engineering rules derived from past incidents, with a tech design checklist
- **Hot Zones Map** — which components carry the most historical risk
- **Pre-edit hook** — warns Claude Code before touching a historically fragile file

---

## Step 5 — Ship features with commands

Once the knowledge base is in place, use these commands in Claude Code for day-to-day delivery:

| Command | When to use |
|---------|-------------|
| `/af-ship <description>` | New feature from scratch — Claude writes the PRD, challenges it, writes the tech design, implements, and produces a feature doc |
| `/af-ship --prd <url-or-path>` | You already have a PRD in Notion or as a local file |
| `/af-ship --tech-design <url-or-path>` | You already have a tech design — skips straight to implementation |
| `/af-quiz-me` | Generates a 10-question browser quiz from a tech design to verify the author or reviewer understands the feature |

**Example:**
```
/af-ship Add a retry mechanism to the event flush pipeline
```

The workflow pauses for your approval at: PRD → tech design → implementation → feature doc.

---

## What gets created

After setup, your repo will have:

```
.claude/
├── WORKFLOW.md                      — skill communication map
├── commands/
│   ├── af-ship.md                   — /af-ship entry point
│   ├── af-ship-from-prd.md          — /af-ship-from-prd entry point
│   ├── af-ship-from-tech-design.md  — /af-ship-from-tech-design entry point
│   └── af-quiz-me.md              — /af-quiz-me command
├── skills/
│   ├── af-ship-orch/SKILL.md        — workflow router
│   ├── alice-pm/SKILL.md            — PM agent (PRD, challenges)
│   ├── dave-<domain>-engineer/SKILL.md  — engineering agent (code, tech design)
│   ├── bob-<domain>-researcher/SKILL.md — research agent (platform/API)
│   └── erin-<domain>-analyst/SKILL.md   — payload/schema agent
└── prompts/
    ├── generate-feature-catalog.md    — feature catalog builder
    └── generate-issue-cases.md      — issue case bank builder
CLAUDE.md                            — project rules and agent contracts
templates/
└── af-tech-quiz-template.html       — quiz UI template
```

And after running the prompts:

```
docs/
├── features/
│   ├── INDEX.md                     — feature catalog index
│   ├── DIAGRAM.md                   — runtime + initialization dependency diagrams
│   └── F-NNN-*.md                   — one file per feature
├── issue-cases/
│   ├── INDEX.md                     — issue case index + hot zones map
│   ├── GUARDRAILS.md                — engineering rules derived from past bugs
│   └── IC-NNN-*.md                  — one file per issue case
├── prds/                            — PRDs written during /af-ship
├── tech-designs/                    — tech designs written during /af-ship
└── researches/                      — research logs written by Bob
```
