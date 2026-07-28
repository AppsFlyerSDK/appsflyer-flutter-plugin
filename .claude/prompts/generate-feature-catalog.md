# Prompt: Create Feature Catalog

Use this prompt to generate a `internal-docs/features/` catalog for this project.
Values below are filled during workflow setup — edit them here if needed.

---

## Inputs

```
PROJECT_CONTEXT:   Flutter plugin providing mobile attribution and analytics for iOS and Android, bridging native AppsFlyer SDKs via Dart MethodChannel/EventChannel
LANGUAGES:         Dart, Objective-C, Java, Kotlin
NOTION_DB_URL:     
NOTION_KEYWORDS:   
JIRA_PROJECT_KEY:  DELIVERY
```

---

## Prompt

````
Create a feature catalog for this project under `internal-docs/features/`.

Project context: Flutter plugin providing mobile attribution and analytics for iOS and Android, bridging native AppsFlyer SDKs via Dart MethodChannel/EventChannel
Primary language(s): Dart, Objective-C, Java, Kotlin

---

## Step 0 — Create workflow tasks

Call `TaskCreate` for each step in order to give a live progress view:

| Subject | activeForm |
|---------|------------|
| Check docs & external sources | Checking availability |
| Discover features from code | Scanning codebase |
| Verify & prune feature list | Verifying features |
| User reviews feature list | Waiting for approval |
| Propose taxonomy | Proposing categories |
| User reviews taxonomy | Waiting for approval |
| Write feature catalog | Writing feature docs |
| Dependency audit | Auditing dependencies |
| Notion enrichment | Enriching from Notion |
| Jira enrichment | Enriching from Jira |

Immediately mark "Check docs & external sources" as `in_progress`.

---

## Phase 0 — Check web docs and Notion availability

### Part A — Web docs (optional — edit the list below before running)

WEB_DOCS_URLS:
  (none — add official documentation URLs here if available, one per line)

If no URLs are listed above, say "No web docs URL provided — skipping Phase 0A" and proceed to Part B.

If URLs are listed above:
1. Fetch the main page of each URL.
2. Discover the navigation structure (sitemap, sidebar links, category pages).
3. Build a list of relevant sub-pages whose titles match the project domain. Keep this list in memory — do NOT fetch sub-pages yet.
4. Say: "Web docs detected. Found N candidate pages. Context will be fetched per-feature during Phase 3 Business Purpose writing."

Do not fetch sub-pages now. Proceed to Part B.

### Part B — Check Notion availability

If NOTION_DB_URL is provided, say:
"Notion URL detected. Business Purpose enrichment will happen in Phase 4, after the catalog is built. Proceeding to Phase 1."
Then proceed to Phase 1. Do not fetch Notion yet.

If NOTION_DB_URL is blank, pause and say exactly:

> **Action required — Notion enrichment**
>
> The **Business Purpose** section is the most valuable part of each feature doc — it answers "what does the product lose if this feature is deleted?" Code alone rarely answers that question; it lives in product specs, PRDs, and design documents.
>
> If your team stores specs or PRDs in Notion, providing a database URL now means every feature doc gets its Business Purpose enriched automatically in Phase 4.
>
> - **Do you have a Notion database with product specs or PRDs for this project?**
>   - Reply with the Notion database URL to enable enrichment. You can also add keywords to filter pages (e.g. `launch, attribution, session`) — if you don't, **`Flutter plugin providing mobile attribution and analytics for iOS and Android, bridging native AppsFlyer SDKs via Dart MethodChannel/EventChannel`** (the project name) will be used as the default filter.
>   - Reply **skip** to proceed without Notion — Business Purpose sections will be derived from code only and marked `> TODO: enrich from product specs`.

Wait for the user's reply before continuing.
- If they provide a URL: store it as NOTION_DB_URL. If they also provided keywords store them as NOTION_KEYWORDS; otherwise set NOTION_KEYWORDS to the project name from PROJECT_CONTEXT. Confirm "Notion enrichment enabled. Proceeding to Phase 1." and proceed.
- If they reply **skip**: say "Proceeding without Notion. Business Purpose sections will be marked TODO." and proceed to Phase 1.

---

## Phase 1 — Discover features from code (no classification yet)

Mark "Check docs & external sources" as completed. Mark "Discover features from code" as `in_progress`.

Read the project's public interfaces, entry points, core implementation files, and any existing documentation under `docs/`. Scan every subdirectory.

Use the language(s) listed in the inputs to determine where public interfaces live:

| Language | Where to look |
|---|---|
| **Swift / Objective-C** | `.h` public headers, `public`/`open` Swift declarations, module maps |
| **Kotlin / Java** | `public` class/interface declarations, `@JvmStatic`, object companions |
| **Go** | Exported identifiers in `pkg/`, `cmd/` entry points, `internal/` |
| **Python** | `__init__.py` exports, `def`/`class` in `src/` or top-level packages |
| **TypeScript / JavaScript** | `index.ts/js`, `export` statements, React component files |
| **Bash / Shell** | Top-level scripts, `function` declarations, sourced library files |
| **Terraform** | `resource`, `module`, `data` blocks; `variables.tf`; `outputs.tf` |

For each discrete capability, output one line:
  F-NNN (provisional) | Feature Name | One-sentence purpose | Key file(s)

Do NOT assign categories yet. Aim for comprehensive coverage — prefer over-listing and pruning to under-listing.

---

## Phase 1.5 — Verify every feature has code in this project

Mark "Discover features from code" as completed. Mark "Verify & prune feature list" as `in_progress`.

For every feature:
- Confirm at least one file in this repository implements or exposes it.
- If no file can be found, mark it ❌ and explain why (server-side only, separate repo, third-party, documentation only, etc.).

Remove all ❌ features. Present the pruned list with a short note on what was removed. Mark "Verify & prune feature list" as completed. Mark "User reviews feature list" as `in_progress`. Wait for confirmation before continuing to Phase 2.

---

## Phase 2 — Propose a taxonomy

Mark "User reviews feature list" as completed. Mark "Propose taxonomy" as `in_progress`.

Propose 3–6 categories that fit this project's domain. Do not import categories from other projects.

**Naming rule:** Category names must be valid mermaid identifiers — alphanumeric and underscores only. No hyphens. Use camelCase for multi-word names (e.g. `deepLinking`, not `deep-linking`).

For each proposed category:
- Name it (camelCase if multi-word)
- One sentence: what kind of feature belongs here
- Which discovered features you would place in it

Mark "Propose taxonomy" as completed. Mark "User reviews taxonomy" as `in_progress`. Present the proposed taxonomy and wait for approval before continuing to Phase 3.

---

## Phase 3 — Create `internal-docs/features/`

Mark "User reviews taxonomy" as completed. Mark "Write feature catalog" as `in_progress`.

### `INDEX.md`
One table per category. Columns: `ID | Name | Status | Platform`. Assign final sequential IDs (F-001, F-002, …). Most foundational feature = F-001.

### `TEMPLATE.md`

~~~markdown
---
id: F-NNN
name: Feature Name
type: [category]
platform: [platform]
status: active / planned / deprecated
last_verified: YYYY-MM-DD
depends_on: []
---

## Business Purpose
Why this feature exists. What the user or product loses if it is removed.

---

## Trigger
When this feature runs. What condition activates it.

---

## Call Chain
\`\`\`
EntryPoint::method()
  → NextLayer::method()    [file]
    → FinalLogic::method() [file]
\`\`\`

---

## Files
| File | Role |
|------|------|

---

## Input / Output
| | |
|--|--|
| **Input** | What comes in |
| **Output** | What goes out |

---

## Tests
`path/to/test_file` — what the tests cover.

---

## Known Limitations
- Limitation — why it exists, what the risk is

---

## Dependencies
```mermaid
flowchart LR
    FXXX["F-XXX · This Feature"]:::typeA -->|"relationship"| FYYY["F-YYY · Other Feature"]:::typeB
    [classDef blocks — one per approved category]
```
~~~

### Individual `F-NNN-[slug].md` for every feature

Fill all sections from actual code. Business Purpose: derive from code what removing this feature breaks, then enrich from web docs if available. If a section does not apply, remove it. If you cannot fill a section, write `> TODO:` — do not fabricate.

If Notion was skipped in Phase 0B, end every **Business Purpose** section with:
`> TODO: enrich from product specs — provide a Notion database URL and re-run Phase 4 to fill this automatically.`

---

### `DIAGRAM.md`

Write after all `F-NNN-*.md` files are complete. Aggregate the `depends_on` frontmatter and mermaid edges from every feature file into one document with three sections:

**Section 1 — Runtime Flow** (`flowchart TD`)

One subgraph per approved category. Include every feature that has at least one outbound or inbound cross-feature edge. Node format: `F001["F-001<br/>Feature Name"]:::category`. One `classDef` block per category (same colors used in individual files). Edges need no label here — topology is enough.

**Section 2 — Initialization Flow** (`flowchart LR`)

Flat diagram (no subgraphs). Include only features that configure, register, gate, or boot other features at startup time. Typically: the SDK init entry point, the service locator / DI container, any boot sequencer, remote-config / feature-flag loaders, and the first-party infrastructure they wire up. Exclude measurement, deep-link, and attribution nodes unless they are explicitly registered during init.

**Section 3 — Dependency Table** (markdown table)

Columns: `Feature | Depends On | Note`. One row per dependency edge. Note should be one sentence explaining _why_ the dependency exists (what the dependant feature gets from the dependency). Include every edge from both diagrams. Sort by Feature ID ascending.

Title format: `# {{PROJECT_NAME}} — Feature Diagrams`

---

## Phase 3.5 — Dependency audit (mandatory, no user input required)

Mark "Write feature catalog" as completed. Mark "Dependency audit" as `in_progress`.

Run immediately after all `F-NNN-*.md` files are written.

**Step 1 — Find all isolated nodes:** features where `depends_on: []` or the mermaid block has only one node with no edges.

**Step 2 — Verify each is genuinely standalone:** check route registration, bootstrap code, client constructors, and orchestration call chains for hidden shared dependencies (middleware, credential providers, utility helpers).

**Step 3 — Fix and report:**

| Feature | Was isolated | Hidden dependency found | Fixed |
|---------|-------------|------------------------|-------|

Mark "Dependency audit" as completed.

---

## Phase 4 — Notion enrich (skip if NOTION_DB_URL is blank)

Mark "Notion enrichment" as `in_progress`.

Run only after all `F-NNN-*.md` files have been created.

1. Tell the user: "Phase 3 complete. Starting Notion enrichment — reply 'skip' to skip, or press Enter to continue." Wait for reply.
2. Fetch the database index at .
3. Filter pages whose title matches: 
4. Before enriching, print a table of all meaningful Notion documents found: Title | Notion ID | Status | Likely enriches.
5. For each feature file: rewrite **only** the `## Business Purpose` section using the most recently edited relevant Notion page. Never paste verbatim.
6. Print Sources Used report: Title | Notion ID | Status | Used to enrich.

Rules: last-edited date is the primary ranking signal. Notion content enriches Business Purpose only. Do not create new feature files from Notion content.

---

## Phase 4B — Jira enrich

Mark "Notion enrichment" as completed. Mark "Jira enrichment" as `in_progress`.

Run after Phase 4 (or Phase 3 if Phase 4 was skipped).

If JIRA_PROJECT_KEY is blank, default it to `DELIVERY`.

Tell the user: "Starting Jira enrichment (project: DELIVERY) — reply 'skip' to skip." Wait for reply. If they skip, mark "Jira enrichment" as completed and end Phase 4B.

1. Proceed with enrichment.
2. Extract the seed ticket from `git branch --show-current`. Walk up to Epic and Initiative.
3. Also run keyword search across project DELIVERY for each feature.
4. Before enriching, print Jira sources found: Key | Title | Type | Updated | Likely enriches.
5. For each feature file: append strategic "why" from Epic/Initiative to Business Purpose; add Known Limitations from Bug issues.
6. Print Jira Sources Used report.

Rules: walk up (Story → Epic → Initiative), never down. Last-updated date is primary ranking signal. Jira enriches Business Purpose and Known Limitations only.

Mark "Jira enrichment" as completed.

---

## Mermaid diagram rules

1. Always use `flowchart LR` for dependency diagrams.
2. Class names must be valid mermaid identifiers (camelCase, no hyphens).
3. Use ` · ` as separator in feature node labels: `F001["F-001 · SDK Initialization"]:::platform`
4. Sanitize special chars in labels: `[`, `]`, `{`, `}`, `<`, `>` → use parentheses or plain text.
5. No UML class body blocks `{ }` inside flowchart.
6. Every arrow must carry a descriptive edge label: `-->|"registers task executor in"|`
7. Color cross-feature nodes by their own category.
8. One distinct fill color per category, always `color:#fff`.

---

## Quality rules

- **Business Purpose** answers: "what does the user or product lose if this is deleted?"
- **Call chains** trace from the public API entry to the leaf implementation.
- **Known Limitations** are honest: evasion vectors, missing coverage, platform gaps.
- **An isolated mermaid node is a red flag.** Confirm in code before leaving it isolated.
- **Dependency diagrams** show only feature-to-feature or feature-to-named-external-system edges.
````
