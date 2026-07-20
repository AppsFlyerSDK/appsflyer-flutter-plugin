# Update Existing Repo — Workflow Skills Patch

Paste this prompt into Claude Code in the repo that already has the skills applied.

---

```
The skill files in this repo need to be updated to match a newer version of the
workflow template. Please apply the following changes exactly. Find each section
by the text shown and replace it with the new content provided.

---

## 1. .claude/skills/alice-feature-orchestrator/SKILL.md

### Change 1 — description frontmatter
Find:
  Also auto-invoked after Bob finishes research or Dave writes a tech design or code.

Replace with:
  Also auto-invoked after Bob finishes research or Dave writes a tech design, code, or feature doc.

---

### Change 2 — Orchestrator Mode steps (full section replacement)
Find this entire block:
  **Step 2 — Write the delegation decision**

  > **Need Bob?** [yes/no] — Reason. Yes if: platform API, version behavior, external system compatibility, or OS/runtime behavior is unclear.
  > **Need Erin?** [yes/no] — Reason. Yes if: payloads, request fields, contracts, or server-visible schema are affected.
  > **Need Dave?** [yes/no] — Usually yes. No only for research-only or documentation-only work.

  **Step 3 — Invoke in order**

  - Bob needed → call `Skill('bob-<domain>-researcher')` immediately after the delegation block.
  - Erin needed → call `Skill('erin-<domain>-analyst')` immediately.
  - Both needed → invoke Bob first if their domains are sequential; otherwise invoke concurrently.
  - Dave → call `Skill('dave-<domain>-engineer')` **only after** Bob/Erin have completed and Alice has updated the PRD if findings changed scope.

  **Step 4 — Update PRD if scope changed**

  If Bob or Erin findings change Requirements, Acceptance criteria, or Risks — rewrite those sections before invoking Dave.

  **Step 5 — Challenge (Challenger Mode)**

  After each of Bob/Dave produces output, shift to Challenger Mode. This is not optional.

  **Step 6 — Close**

  Write `"Satisfied — [Person], this is ready."` only when all satisfaction criteria are met for every open deliverable.

Replace with:
  **Step 2 — Save PRD and ask user to review**

  Save the PRD to `docs/prds/<feature-slug>.md` where `<feature-slug>` is a short kebab-case name (e.g. `device-farm-3d-header`).

  Then write:
  Then write exactly:

  ---
  ## ⏸ Waiting for your review

  PRD saved to `docs/prds/<feature-slug>.md`.
  The workflow is paused. Reply **approved** to continue, or share your feedback and I'll update the PRD.

  ---

  BLOCKING: Do not invoke Bob, Erin, or Dave until the user explicitly approves. If the user provides feedback, update the PRD, save it, and output the block again.

  Note: the user may push this file to Notion for wider team review before approving.

  **Step 3 — Write the delegation decision**

  > **Need Bob?** [yes/no] — Reason. Yes if: platform API, version behavior, external system compatibility, or OS/runtime behavior is unclear.
  > **Need Erin?** [yes/no] — Reason. Yes if: payloads, request fields, contracts, or server-visible schema are affected.
  > **Need Dave?** [yes/no] — Usually yes. No only for research-only or documentation-only work.

  **Step 4 — Invoke in order**

  - Bob needed → call `Skill('bob-<domain>-researcher')` immediately after the delegation block.
  - Erin needed → call `Skill('erin-<domain>-analyst')` immediately.
  - Both needed → invoke Bob first if their domains are sequential; otherwise invoke concurrently.
  - Dave → call `Skill('dave-<domain>-engineer')` **only after** Bob/Erin have completed and Alice has updated the PRD if findings changed scope.

  **Step 5 — Update PRD if scope changed**

  If Bob or Erin findings change Requirements, Acceptance criteria, or Risks — rewrite those sections before invoking Dave.

  **Step 6 — Challenge (Challenger Mode)**

  After each of Bob/Dave produces output, shift to Challenger Mode. This is not optional.

  **Step 7 — Close**

  Write `"Satisfied — [Person], this is ready."` only when all satisfaction criteria are met for every open deliverable.

Note: keep the actual skill names as they appear in this file (e.g. dave-ios-engineer, not the placeholder).

---

### Change 3 — Loop Mechanics block
Find the entire code block inside Loop Mechanics (the ``` block) and replace it with:

  ```
  User presents feature idea
    → Alice writes PRD → saves to docs/prds/<slug>.md → asks user to review
    → User approves PRD
    → Alice invokes Bob and/or Erin if needed
    → Bob/Erin produce findings
    → Alice challenges (Challenger Mode, max 2 iterations)
    → Bob/Erin address every open item
    → Alice updates PRD if scope changed
    → Alice invokes Dave
    → Dave writes tech design → saves to docs/tech-designs/<slug>.md
    → Alice challenges tech design (Challenger Mode, max 2 iterations)
    → Dave addresses every open item
    → Alice: "Satisfied — Dave, this is ready." (on tech design)
    → Dave asks user to review tech design
    → User approves tech design
    → Dave implements + writes unit tests
    → Alice challenges implementation (Challenger Mode, max 2 iterations)
    → Dave addresses every open item
    → Alice: "Satisfied — Dave, this is ready." (on implementation)
    → Dave writes F-NNN feature doc → saves to docs/features/
    → Alice challenges feature doc (Challenger Mode, max 2 iterations)
    → Alice: "Satisfied — Dave, this is ready." (on feature doc)
    → If unresolved after 2 iterations → Alice escalates to user
  ```

---

### Change 4 — Challenge Agenda item 3
Find:
  ### 3. Feature Documentation
  - Is the tech design written and linked?
  - Post-code only: is the F-NNN doc written after Alice says "Satisfied"?

Replace with:
  ### 3. Feature Documentation

  **During tech design review:**
  - Is the tech design saved to `docs/tech-designs/<slug>.md`?
  - Does the tech design cover all PRD requirements and acceptance criteria?
  - Is the planned F-NNN ID noted in the design?

  **During feature doc review (Phase 3 only — do not check during tech design or implementation review):**
  - Is the F-NNN doc written to `docs/features/` and added to `docs/features/INDEX.md`?
  - Does it follow `docs/features/TEMPLATE.md`?
  - Are Business Purpose, Call Chain, Files, and Tests sections complete?

---

### Change 5 — Satisfaction criteria for Dave
Find:
  ### Alice is satisfied with Dave when:
  - [ ] GUARDRAILS context table was present before code
  - [ ] Every touched hot-zone component has IC-NNN coverage stated
  - [ ] Migration and rollout risk addressed — path documented or explicitly not required
  - [ ] F-NNN doc complete or deferred with stated reason
  - [ ] Every Alice risk flag acknowledged with acceptance rationale or rebuttal
  - [ ] No open challenge items without a response

Replace with:
  ### Alice is satisfied with Dave's tech design when:
  - [ ] GUARDRAILS context table was present before the design
  - [ ] Every affected hot-zone component has IC-NNN coverage stated
  - [ ] Migration and rollout risk addressed — path documented or explicitly not required
  - [ ] Planned F-NNN ID noted in the design
  - [ ] Every Alice risk flag acknowledged with acceptance rationale or rebuttal
  - [ ] No open challenge items without a response

  ### Alice is satisfied with Dave's implementation when:
  - [ ] GUARDRAILS context table was present before the code
  - [ ] Every touched hot-zone component has IC-NNN coverage stated
  - [ ] Unit tests cover happy path and key edge cases
  - [ ] Test suite passes
  - [ ] Every Alice risk flag acknowledged with acceptance rationale or rebuttal
  - [ ] No open challenge items without a response

  ### Alice is satisfied with Dave's feature doc when:
  - [ ] F-NNN doc written to `docs/features/` and added to `docs/features/INDEX.md`
  - [ ] All template sections complete (Business Purpose, Call Chain, Files, Tests)
  - [ ] No open challenge items without a response

---

### Change 6 — Docs Locations section
Find:
  ## Feature Docs Location

  PRDs and feature docs land in `<whatever path is here>`.

Replace with:
  ## Docs Locations

  - PRDs → `docs/prds/<slug>.md` (temporary — user may push to Notion for review)
  - Feature catalog docs → `<keep the same path that was here>` (permanent)

---

## 2. .claude/skills/dave-<domain>-engineer/SKILL.md

### Change 1 — Replace tech design and post-code sections
Find this entire block:
  ### During tech design — location choice

  Ask the user before writing:

  > "Where should I write this tech design?
  > 1. **Notion** — tech design board
  > 2. **Local file** — `docs/tech-designs/<ticket-or-feature-slug>.md`"

  Do NOT write tech designs in `docs/features/` — that directory is for finished feature catalog docs only.
  Note the planned F-NNN ID in the design as "F-NNN — doc to be written after development is complete."

  ### After completing a code change

  5. Find which feature docs reference each changed file:
     ```
     grep "ChangedFile" docs/features/INDEX.md
     ```
  6. Update any section whose behavior, public API, configuration, or data flow changed.
  7. If the change introduces a new feature: write the full F-NNN doc and add it to `docs/features/INDEX.md` **only after Alice has written "Satisfied — Dave, this is ready."** Not before.

Replace with:
  ### Phase 1 — Tech design

  Write the tech design to `docs/tech-designs/<feature-slug>.md` where `<feature-slug>` is the same kebab-case slug used for the PRD (e.g. `device-farm-3d-header`).

  Do NOT write tech designs in `docs/features/` — that directory is for finished feature catalog docs only.
  Note the planned F-NNN ID in the design as "F-NNN — doc to be written after development is complete."

  After writing the tech design, call `Skill('<alice-skill-name>')` immediately for review.

  When Alice writes "Satisfied — Dave, this is ready." on the tech design, write:
  When Alice writes "Satisfied — Dave, this is ready." on the tech design, write exactly:

  ---
  ## ⏸ Waiting for your review

  Tech design saved to `docs/tech-designs/<feature-slug>.md`. Alice has signed off.
  The workflow is paused. Reply **approved** to start implementation, or share your feedback.

  ---

  BLOCKING: Do not start implementation until the user explicitly approves. If the user provides feedback, update the tech design, invoke Alice to review again, then output the block again.

  Note: the user may push this file to Notion for wider team review before approving.

  ### Phase 2 — Implementation

  After user approves the tech design:
  - Implement the feature according to the PRD and tech design.
  - Write unit tests covering the happy path and key edge cases.
  - Run the test suite (see Test commands reference below).
  - Call `Skill('<alice-skill-name>')` for implementation review.

  ### Phase 3 — Feature doc

  After Alice writes "Satisfied — Dave, this is ready." on the implementation:

  **Step 1 — Impact scan (do this before writing anything)**

  For every file changed during implementation, run:
  ```
  grep "<changed-file>" docs/features/INDEX.md
  ```
  Run once per changed file. Then print this table:

  | Changed file | Affected F-NNN docs |
  |---|---|
  | `path/to/file` | F-NNN, F-NNN or "none" |

  For every affected F-NNN doc found: open it and update every section whose behavior, public API, configuration, or data flow changed. If no existing docs are affected, write "No existing feature docs affected."

  **Step 2 — Write the new feature doc**

  Write the full F-NNN feature catalog doc to `docs/features/<F-NNN-slug>.md` and add it to `docs/features/INDEX.md`.

  **Step 3 — Call Alice**

  Call `Skill('<alice-skill-name>')` to review. This is a separate Alice review loop focused only on feature docs — not the code.

Note: replace `<alice-skill-name>` with the actual skill name used in this file (e.g. `alice-feature-orchestrator`).

---

### Change 2 — Test commands section header and note
Find:
  ### Test commands

  ```
  <test commands are here>
  ```

Replace with:
  ### Test commands reference

  ```
  <keep the same test commands>
  ```

  Run after every implementation change (Phase 2) before calling Alice.

---

### Change 3 — Alice Review Loop trigger
Find:
  After producing ANY code or tech design output, call `Skill('alice-feature-orchestrator')` immediately.

Replace with:
  After producing ANY code, tech design, or feature doc output, call `Skill('alice-feature-orchestrator')` immediately.

(Use the actual alice skill name as it appears in the file.)

---

## 3. .claude/skills/bob-<domain>-researcher/SKILL.md

### Change 1 — Remove line from Alice Review Loop section
Find and delete this line (it appears just after the sentence about the loop closing):
  If Alice ends her output with "Bob —", Bob must respond in the next turn.

---

## 4. .claude/skills/erin-<domain>-analyst/SKILL.md

### Change 1 — Context field in analysis doc format
Find:
  What triggered this analysis — customer report, QA finding, CI diff, etc.

Replace with:
  What triggered this analysis — PRD requirement for [feature], customer report, QA finding, CI diff, etc.

---

---

## 5. .claude/WORKFLOW.md

### Change 1 — Mermaid diagram entry arrow
Find:
  User -->|"feature / PRD / impl request"| Alice

Replace with:
  User -->|"/af-ship"| Alice

---

### Change 2 — Docs Layer table (full replacement)
Find:
  | `<feature doc path>` | Feature catalog | Dave (writes F-NNN) | Alice, Bob, Erin (read) |
  | `docs/issue-cases/` | Scar book | Human / eng team | Alice, Dave, Bob, Erin (read) |
  | `<research path>` | Research log | Bob (writes R-NNN) | Alice (via challenge loop) |
  | `docs/payloads/` | Payload map | Erin (writes P-NNN, FIELD_MAP) | Alice, Dave (via challenge loop) |

Replace with:
  | `docs/prds/` | PRDs (staging) | Alice (writes) | User review; may move to Notion |
  | `docs/tech-designs/` | Tech designs (staging) | Dave (writes) | User review; may move to Notion |
  | `<keep the same feature doc path>` | Feature catalog | Dave (writes F-NNN) | Alice, Bob, Erin (read) |
  | `docs/issue-cases/` | Scar book | Human / eng team | Alice, Dave, Bob, Erin (read) |
  | `<keep the same research path>` | Research log | Bob (writes R-NNN) | Alice (via challenge loop) |
  | `docs/payloads/` | Payload map | Erin (writes P-NNN, FIELD_MAP) | Alice, Dave (via challenge loop) |

Note: preserve the actual paths already in the file for feature docs and research.

---

### Change 3 — Invocation Rules table (full replacement)
Find the entire Invocation Rules table block (from `| Entry point |` through the "If unsure" line) and replace with:

  | Entry point | When |
  |-------------|------|
  | `/af-ship <description>` → Alice | Starting any feature — PRD, tech design, implementation, feature doc |
  | Dave (direct) | Maintenance only: logs, renames, dead-code removal, comment cleanup, test additions, minor refactors with no public API change |
  | Bob (direct) | Ad-hoc platform/API research not tied to a feature |
  | Erin (direct) | Ad-hoc payload or schema analysis not tied to a feature |
  | Bob | Invoked by Alice when platform API / version / external behavior is unclear |
  | Erin | Invoked by Alice when payloads, request fields, or server-visible schema is affected |

  If unsure whether a task is maintenance or a feature → use `/af-ship`.

---

### Change 4 — Loop Mechanics block (full replacement)
Find the entire code block inside Loop Mechanics (the ``` block) and replace with:

  ```
  User runs /af-ship <description>
    → Alice writes PRD → saves to docs/prds/<slug>.md → asks user to review
    → User approves PRD
    → Alice invokes Bob and/or Erin if needed
    → Bob/Erin produce findings
    → Alice challenges (max 2 iterations)
    → Alice updates PRD if scope changed
    → Alice invokes Dave

  Phase 1 — Tech design
    → Dave writes tech design → saves to docs/tech-designs/<slug>.md
    → Alice challenges tech design (max 2 iterations)
    → Alice: "Satisfied — Dave, this is ready." (on tech design)
    → Dave asks user to review tech design
    → User approves tech design

  Phase 2 — Implementation
    → Dave implements + writes unit tests
    → Alice challenges implementation (max 2 iterations)
    → Alice: "Satisfied — Dave, this is ready." (on implementation)

  Phase 3 — Feature doc
    → Dave writes F-NNN feature doc → saves to docs/features/
    → Alice challenges feature doc (max 2 iterations)
    → Alice: "Satisfied — Dave, this is ready." (on feature doc)
  ```

---

## 6. .claude/commands/af-ship.md (NEW FILE — create if it does not exist)

Create this file at `.claude/commands/af-ship.md` with the following content exactly:

  Start the full feature delivery workflow for the following feature:

  $ARGUMENTS

  Invoke the `alice-feature-orchestrator` skill now to begin. Alice will write a PRD,
  save it to docs/prds/, ask for your review, then coordinate research and engineering
  through tech design, implementation, and feature documentation.

---

## 7. CLAUDE.md

### Change 1 — Replace entire file content
Replace the full contents of CLAUDE.md with:

  # <repo name> AI Workflow

  ## Starting a feature

  To start the full feature delivery workflow, use the slash command:

  ```
  /af-ship <short description>
  ```

  This invokes Alice, who writes a PRD, coordinates Bob and Erin if needed, and
  manages Dave through tech design, implementation, and feature documentation.
  Nothing else triggers the full workflow — all other requests go directly to the
  relevant skill.

  ## Direct invocation

  For everything outside of feature delivery, invoke skills directly:

  | Task | Invoke |
  |------|--------|
  | Code question, architecture, implementation | `dave-<domain>-engineer` |
  | Maintenance task (see list below) | `dave-<domain>-engineer` |
  | Platform API research, version behavior | `bob-<domain>-researcher` |
  | Payload analysis, field mapping, schema review | `erin-<domain>-analyst` |

  ## Maintenance tasks

  The following do not require a PRD or Alice review — invoke Dave directly:

  <paste existing maintenance tasks list here>

  ## Output contract

  Every `/af-ship` deliverable must include:

  - Alice PRD (`docs/prds/`)
  - Bob findings (if invoked)
  - Erin payload impact (if invoked)
  - Dave tech design (`docs/tech-designs/`)
  - Dave implementation + unit tests
  - Dave feature doc (`docs/features/`)
  - Alice sign-off at each phase

Note: preserve the existing maintenance tasks list and skill names (domain-specific).

---

## 8. .claude/skills/alice-feature-orchestrator/SKILL.md (continued)

### Change 3 — description frontmatter (full replacement)
Find:
  description: Use for ANY feature idea, PRD request, product request, or implementation request — Alice is PM owner, orchestrator, and release gate and runs first. Also auto-invoked after Bob finishes research or Dave writes a tech design, code, or feature doc. Alice challenges both on completeness, version coverage, compliance risk, GUARDRAILS compliance, and business impact.

Replace with:
  description: Auto-invoked after Bob finishes research or Dave writes a tech design, code, or feature doc — challenge and close the loop. Also invoked by the /af-ship command to start a new feature. Do NOT invoke for questions, ad-hoc analysis, research, or maintenance tasks.

---

### Change 4 — Orchestrator Mode trigger line
Find:
  **Trigger:** User presents a feature idea, vague request, PRD request, or implementation request.

Replace with:
  **Trigger:** User runs `/af-ship <description>`.

---

### Change 5 — Auto-invocation rule trigger
Find:
  **When user presents a feature idea, PRD request, product request, or implementation request:**
  BLOCKING REQUIREMENT: Call the `Skill` tool with `alice-feature-orchestrator` BEFORE any other response. Do not write code, investigate the codebase, or ask clarifying questions before Alice has produced a PRD.

Replace with:
  **When `/af-ship` command is run:**
  BLOCKING REQUIREMENT: Call the `Skill` tool with `alice-feature-orchestrator` BEFORE any other response. Do not write code, investigate the codebase, or ask clarifying questions before Alice has produced a PRD.

---

---

### Change 6 — Alice satisfaction criteria for feature doc
Find:
  ### Alice is satisfied with Dave's feature doc when:
  - [ ] F-NNN doc written to `docs/features/` and added to `docs/features/INDEX.md`
  - [ ] All template sections complete (Business Purpose, Call Chain, Files, Tests)
  - [ ] No open challenge items without a response

Replace with:
  ### Alice is satisfied with Dave's feature doc when:
  - [ ] Impact scan table was printed — every changed file checked against `docs/features/INDEX.md`
  - [ ] All affected existing F-NNN docs updated, or "none affected" explicitly stated
  - [ ] F-NNN doc written to `docs/features/` and added to `docs/features/INDEX.md`
  - [ ] All template sections complete (Business Purpose, Call Chain, Files, Tests)
  - [ ] No open challenge items without a response

---

After applying all changes, confirm which files were updated.
```
