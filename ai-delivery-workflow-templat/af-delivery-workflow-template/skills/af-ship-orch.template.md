---
name: af-ship-orch
description: Workflow entry point orchestrator for /af-ship, /af-ship-from-prd, and /af-ship-from-tech-design. Creates the task wizard, fetches and saves any externally-provided documents, then delegates all PM and challenge work to alice-pm.
---

# af-ship Orchestrator

Handles workflow entry. Creates tasks, fetches documents, then calls `alice-pm`.

---

## Mode: New Feature

**Trigger:** `/af-ship <description>`.

**Step 0 — Create workflow tasks**

Call `TaskCreate` for each step in order:

| Subject | activeForm |
|---------|------------|
| Write PRD | Writing PRD |
| User reviews PRD | Waiting for PRD approval |
| Research — Bob / Erin | Researching |
| Dave writes tech design | Writing tech design |
| User reviews tech design | Waiting for tech design approval |
| Dave implements | Implementing |
| Dave writes feature doc | Writing feature doc |

Immediately mark "Write PRD" as `in_progress`.

**Step 1 — Hand off to Alice**

Call `Skill('alice-pm')`. Alice will write the PRD, challenge Bob/Erin/Dave, and close each loop.

---

## Mode: PRD-Given

**Trigger:** `/af-ship-from-prd <url-or-path>` or `/af-ship --prd <url-or-path>`.

**Step 0 — Create workflow tasks**

Call `TaskCreate` for each step in order:

| Subject | activeForm |
|---------|------------|
| Fetch and validate PRD | Fetching PRD |
| Challenge PRD | Challenging PRD |
| Research — Bob / Erin | Researching |
| Dave writes tech design | Writing tech design |
| User reviews tech design | Waiting for tech design approval |
| Dave implements | Implementing |
| Dave writes feature doc | Writing feature doc |

Immediately mark "Fetch and validate PRD" as `in_progress`.

**Step 1 — Validate the argument**

- Starts with `http` → Notion URL
- Ends with `.md` or contains `/` → local file path
- Otherwise → stop and ask: "Please provide a Notion URL or a path to a local `.md` file (e.g. `https://notion.so/team/my-prd` or `docs/prds/my-feature.md`)."

**Step 2 — Fetch or read**

- Notion URL: use the `notion-fetch` MCP tool.
- Local file: read the file directly.

**Step 3 — Save a local copy**

Save to `docs/prds/<slug>.md`.
- Derive `<slug>` from the document title (kebab-case, e.g. `dark-mode-settings`).
- If the file is already at `docs/prds/`, use it in place.
- If no title is detectable, ask: "What slug should I use for this PRD? (e.g. `dark-mode-settings`)"

Mark "Fetch and validate PRD" as `completed`, "Challenge PRD" as `in_progress`.

**Step 4 — Hand off to Alice**

Call `Skill('alice-pm')` in PRD-Given mode, passing the saved path. Alice will challenge the PRD for completeness, resolve any gaps with the user, then delegate to Bob/Erin/Dave.

---

## Mode: Tech-Design-Given

**Trigger:** `/af-ship-from-tech-design <url-or-path>` or `/af-ship --tech-design <url-or-path>`.

**Step 0 — Create workflow tasks**

Call `TaskCreate` for each step in order:

| Subject | activeForm |
|---------|------------|
| Fetch and validate tech design | Fetching tech design |
| Challenge tech design | Challenging tech design |
| User reviews tech design | Waiting for tech design approval |
| Dave implements | Implementing |
| Dave writes feature doc | Writing feature doc |

Immediately mark "Fetch and validate tech design" as `in_progress`.

**Step 1 — Validate the argument**

- Starts with `http` → Notion URL
- Ends with `.md` or contains `/` → local file path
- Otherwise → stop and ask: "Please provide a Notion URL or a path to a local `.md` file (e.g. `https://notion.so/team/my-design` or `docs/tech-designs/my-feature.md`)."

**Step 2 — Fetch or read**

- Notion URL: use the `notion-fetch` MCP tool.
- Local file: read the file directly.

**Step 3 — Save a local copy**

Save to `docs/tech-designs/<slug>.md`.
- Derive `<slug>` from the document title (kebab-case).
- If the file is already at `docs/tech-designs/`, use it in place.
- If no title is detectable, ask: "What slug should I use for this tech design? (e.g. `dark-mode-settings`)"

Mark "Fetch and validate tech design" as `completed`, "Challenge tech design" as `in_progress`.

**Step 4 — Hand off to Alice**

Call `Skill('alice-pm')` in Tech-Design-Given mode, passing the saved path. Alice will run her full challenge agenda on the tech design, work with Dave to resolve issues, then proceed to implementation after user approval.

---

## ⚡ Auto-Invocation Rules — BLOCKING REQUIREMENTS FOR CLAUDE

**When `/af-ship` command is run:**
BLOCKING REQUIREMENT: Call the `Skill` tool with `af-ship-orch` BEFORE any other response. Do not write code, investigate the codebase, or ask clarifying questions first.

**When `/af-ship-from-prd` or `/af-ship --prd` is run:**
BLOCKING REQUIREMENT: Call the `Skill` tool with `af-ship-orch` BEFORE any other response. Do not fetch, read, or analyze the PRD before invoking the orchestrator.

**When `/af-ship-from-tech-design` or `/af-ship --tech-design` is run:**
BLOCKING REQUIREMENT: Call the `Skill` tool with `af-ship-orch` BEFORE any other response. Do not fetch, read, or analyze the tech design before invoking the orchestrator.

---

## Loop Mechanics

```
/af-ship <description>
  → af-ship-orch creates tasks → calls alice-pm
  → Alice writes PRD → saves to docs/prds/<slug>.md → asks user to review
  → User approves PRD
  → Alice invokes Bob and/or Erin if needed
  → Bob/Erin produce findings → Alice challenges (max 2 iterations)
  → Alice updates PRD if scope changed
  → Alice invokes Dave
  → Dave writes tech design → saves to docs/tech-designs/<slug>.md
  → Alice challenges tech design (max 2 iterations)
  → Alice: "Satisfied — Dave, this is ready." (on tech design)
  → Dave asks user to review tech design
  → User approves tech design
  → Dave implements + writes unit tests
  → Alice challenges implementation (max 2 iterations)
  → Alice: "Satisfied — Dave, this is ready." (on implementation)
  → Dave writes F-NNN feature doc → saves to docs/features/
  → Alice challenges feature doc (max 2 iterations)
  → Alice: "Satisfied — Dave, this is ready." (on feature doc)
  → If unresolved after 2 iterations → Alice escalates to user

/af-ship-from-prd <url-or-path>
  → af-ship-orch fetches/saves PRD → calls alice-pm (PRD-Given mode)
  → Alice challenges PRD → delegates to Bob/Erin/Dave → standard flow

/af-ship-from-tech-design <url-or-path>
  → af-ship-orch fetches/saves tech design → calls alice-pm (Tech-Design-Given mode)
  → Alice challenges tech design → Dave addresses → user approves → standard flow from implementation
```

**The loop closes only when Alice explicitly writes:**
> "Satisfied — [Bob/Dave], this is ready."

Anything short of that phrase keeps the loop open.
