# Prompt: Generate Issue Cases from Git History

Copy and paste the block below into the target Claude Code session.
Values below are filled during workflow setup — edit them here if needed.

---

## Inputs

```
PROJECT_CONTEXT:  {{PROJECT_CONTEXT}}
LANGUAGES:        {{LANGUAGES}}
```

---

## TASK

Mine this repository's full git history across all branches and generate `docs/issue-cases/` — an engineering issue case bank with a hot zones map and two-axis classification (Component × Bug Class).

Project context: {{PROJECT_CONTEXT}}
Primary language(s): {{LANGUAGES}}

Create `docs/issue-cases/INDEX.md`, `docs/issue-cases/TEMPLATE.md`, `docs/issue-cases/GUARDRAILS.md`, and individual `IC-NNN-*.md` files.

---

## Step 0 — Create workflow tasks

Call `TaskCreate` for each step in order to give a live progress view:

| Subject | activeForm |
|---------|------------|
| Spawn year agents | Spawning agents |
| Mine git history | Mining commits |
| Cross-check with Jira | Verifying Jira bugs |
| Align IC cases | Aligning cases |
| Build hot zones map | Mapping hot zones |
| Write individual IC cases | Writing cases |
| Generate GUARDRAILS.md | Writing guardrails |
| Write INDEX.md | Writing index |
| Dependency audit | Auditing dependencies |
| Update CLAUDE.md | Updating CLAUDE.md |
| Add pre-edit hook | Adding hook |
| Update persona skills | Updating skills |

Immediately mark "Spawn year agents" as `in_progress`.

---

## Step 0.5 — Detect repo years and spawn parallel mining agents

Determine which calendar years to mine (last 9 years maximum):

```bash
CURRENT_YEAR=$(date +%Y)
OLDEST_YEAR=$((CURRENT_YEAR - 8))
FIRST_COMMIT_YEAR=$(git log --all --format="%ad" --date=format:"%Y" | sort -n | head -1)
START_YEAR=$(( FIRST_COMMIT_YEAR > OLDEST_YEAR ? FIRST_COMMIT_YEAR : OLDEST_YEAR ))
echo "Mining years: $START_YEAR to $CURRENT_YEAR"
```

Create the staging directory:

```bash
mkdir -p docs/issue-cases/partial
```

For each year from `$START_YEAR` to `$CURRENT_YEAR`, spawn one Agent in parallel. Pass the prompt below verbatim, substituting:
- `{{YEAR}}` with the actual 4-digit year integer (e.g., `2021`)
- `{{YEAR+1}}` with the actual year plus one (e.g., `2022`)
- `{{PROJECT_CONTEXT}}` with the PROJECT_CONTEXT input value
- `{{LANGUAGES}}` with the LANGUAGES input value

---

**Year-agent prompt (embed once per agent, substituting {{YEAR}}):**

```
You are mining a single calendar year of git history to find bug-fix commits.

Year to mine: {{YEAR}}
Project context: {{PROJECT_CONTEXT}}
Primary language(s): {{LANGUAGES}}

## Your task

Run the following to find candidate commits for {{YEAR}} only:

git log --all --oneline \
  --after="{{YEAR}}-01-01" \
  --before="{{YEAR+1}}-01-01" \
  --grep="fix\|bug\|crash\|issue\|error\|fail\|wrong\|broken\|incorrect\|hotfix\|patch\|revert\|regression\|workaround\|overflow\|leak\|null\|cast\|race\|deadlock\|corrupt\|invalid\|mismatch\|NPE\|ClassCast\|NullPointer\|ArityException" \
  -i

For each candidate commit, inspect the full diff:
  git show <hash>

Include only genuine bug fixes — skip pure refactors, dependency bumps, CI/config-only changes.

For each confirmed bug fix, collect:
- Commit hash
- Short description
- Component/file affected
- What the fix was
- Severity: CRITICAL / HIGH / MEDIUM / LOW / BLOCKER
- Bug class: concurrency / null-safety / type-system / logic-error / memory-safety / serialization / state-management / api-contract / build-pipeline / security-gap
- Ticket number if present (e.g. DELIVERY-XXXXX)

## Output format

Write one file per bug fix to docs/issue-cases/partial/ using this name pattern:
  {{YEAR}}-NNN-kebab-short-name.md
where NNN is a zero-padded counter starting at 001, scoped to this year only.

File content:

---
commit: <hash>
year: {{YEAR}}
---

## {{YEAR}}-NNN — [Short Name]

**Component:** `file/path` or layer name
**Bug class:** [class]
**Severity:** [severity]
**Ticket:** [TICKET-XXXXX or —]
**Commit:** `hash`
**Date:** [YYYY-MM-DD from git log --format="%ad" --date=short <hash>]

### What Happened
[1–3 sentences]

### Observable Symptom
[How it manifested]

### Root Cause
[Technical reason]

### Fix Applied
[What was changed]

### Takeaway
[The rule that prevents this class of bug. Be specific to this codebase.]

Also write a one-line summary file docs/issue-cases/partial/{{YEAR}}-index.md listing each case you wrote:
  {{YEAR}}-NNN-kebab-name.md — [one-line summary]

If you find zero genuine bug fixes for {{YEAR}}, write docs/issue-cases/partial/{{YEAR}}-index.md with a single line:
  no cases found
```

---

Wait for all year-agents to complete before continuing.

Mark "Spawn year agents" as completed.

---

## Step 1 — Mine the git history (ALL branches, ALL eras)

> **Note:** Mining is handled by the parallel year-agents in Step 0.5. Skip this step and proceed to Step 1b.

**Depth expectation: a mature service with 9+ years of history should yield at least 25–35 cases. If you find fewer than 20, you have not mined deeply enough — go back and expand the search before continuing.**

Run a single broad search across all commits with no count cap:

```bash
git log --all --oneline | wc -l   # to see total commit count
git log --all --oneline --grep="fix\|bug\|crash\|issue\|error\|fail\|wrong\|broken\|incorrect\|hotfix\|patch\|revert\|regression\|workaround\|overflow\|leak\|null\|cast\|race\|deadlock\|corrupt\|invalid\|mismatch\|NPE\|ClassCast\|NullPointer\|ArityException" -i
```

If the grep returns more than 200 matches, process them in batches of 100 by date. Inspect the actual diff of each matching commit (`git show --stat <hash>`) to determine whether it is a genuine bug fix or an unrelated change that happens to use a keyword.

**Era coverage — pay special attention to the earliest 20% of commits.** Early-era code (the first 2–3 years) typically contains foundational bugs in storage, lifecycle, and concurrency patterns that recur throughout the codebase. Do not assume recent commits tell the full story.

For each genuine bug-fix commit collect:
- Commit hash + branch (if identifiable)
- Short description of the issue
- Component/file affected
- What the fix was
- Severity (see definitions below)
- Bug class (see taxonomy below)
- Ticket number if present in the commit message (e.g. `DELIVERY-NNNNN`)
- Branch creation date if the branch name is available: `git log --format="%ad" --date=short <hash> | tail -1`

---

## Step 1b — Cross-check with Jira confirmed Bugs

Mark "Mine git history" as completed. Mark "Cross-check with Jira" as `in_progress`.

After mining git history, extract every DELIVERY-XXXXX ticket number mentioned in commit messages and check Jira to verify which are confirmed `issuetype = Bug`. This surfaces bugs that may have had minimal or keyword-free commit messages.

```bash
# Extract DELIVERY ticket numbers from full git log
git log --all --oneline | grep -oE 'DELIVERY-[0-9]+' | sort -u
```

For each unique DELIVERY-XXXXX number found:
1. Query Jira using `searchJiraIssuesUsingJql` in batches of 50:
   ```
   issuetype = Bug AND key in (DELIVERY-XXXXX, ...)
   ```
2. For each confirmed Bug ticket not already covered by an IC case:
   - Fetch the full issue (`getJiraIssue`) — if the response is large, save to a temp file and extract text with Python
   - Record the ticket's `created` date from the Jira response (use as the **Date** field in the IC case)
   - Find the corresponding fix commit in git (`git log --all --oneline --grep="DELIVERY-XXXXX"`)
   - Inspect the diff (`git show <hash>`)
   - Write the IC case to `docs/issue-cases/partial/JIRA-NNN-kebab-short-name.md` (where NNN is a zero-padded counter starting at 001, scoped to this step). Use the same file format as the year-agent cases (frontmatter with `commit:` and `year:` fields, then the IC sections). Step 1b.5 will collect and align all partial files together.

Skip tickets where the diff shows only infrastructure changes (Dockerfile, CI config, `.edn` config files with no behavior change).

---

## Step 1b.5 — Align all partial cases to final IC-NNN format

Mark "Cross-check with Jira" as completed. Mark "Align IC cases" as `in_progress`.

**Collect** all files matching `docs/issue-cases/partial/????-???-*.md`.

**Deduplicate** by commit hash: read the `commit:` frontmatter field from each file. If two files share the same hash, keep the one with more lines (richer description) and discard the other.

**Sort** remaining files by the `Date:` field in their body (YYYY-MM-DD), oldest first. If a file has no date, sort it after all dated files.

**Renumber** sequentially starting at 1. Assign each file a new ID: `IC-001`, `IC-002`, ..., `IC-NNN`.

**Rename** each file from its temp name to its final name:
- `docs/issue-cases/partial/2019-003-null-dereference.md` → `docs/issue-cases/IC-007-null-dereference.md`
- Pattern: strip the `YYYY-NNN-` prefix, prepend `IC-NNN-` (using the new sequential number, zero-padded to 3 digits)

**Update** the heading inside each renamed file from `## YYYY-NNN — Name` to `## IC-NNN — Name`.

Report a summary table of all actions taken:

| Temp ID | Final ID | Commit | Date | Action |
|---------|----------|--------|------|--------|
| 2019-001-foo | IC-001-foo | abc1234 | 2019-03-12 | renamed |
| 2020-002-bar | — | def5678 | 2020-07-01 | duplicate, discarded |

**Clean up** the staging directory after confirming all files have been moved to `docs/issue-cases/`:
```bash
rm -rf docs/issue-cases/partial/
```

Mark "Align IC cases" as completed.

---

## Step 2 — Build the Hot Zones Map

Mark "Align IC cases" as completed. Mark "Build hot zones map" as `in_progress`.

Produce a **hot zones map**: a ranked table of components by fix-commit count, with the dominant bug class per component shown visually.

Count fix-commit frequency using:
```bash
git log --all --oneline --diff-filter=M -- <path-to-component-file> | wc -l
```

```
## Hot Zones Map

| Component | Fix Commits | Dominant Bug Classes | Cases |
|-----------|-------------|----------------------|-------|
| `FileName` | ████████ 8 | logic-error × 4, concurrency × 3 | IC-001, IC-003... |
```

Bar width: 1 block per 5 fix commits, max 10 blocks.
List the top 10–15 components ranked by fix-commit count.

---

## Step 3 — Write Individual Cases

Mark "Build hot zones map" as completed. Mark "Write individual IC cases" as `in_progress`.

Name each file `IC-NNN-kebab-case-short-name.md`.

```
## IC-NNN — [Short Name]

**Component:** `file/path` or layer name
**Bug class:** [see taxonomy]
**Severity:** CRITICAL / HIGH / MEDIUM / LOW / BLOCKER
**Ticket:** [TICKET-XXXXX or —]
**Commit:** `hash`
**Branch:** [branch name or —]
**Date:** [YYYY-MM-DD — ticket created (from Jira) or branch created (from git), whichever is available; omit if neither is known]

### What Happened
[1–3 sentences: what the bug was and where it lived]

### Observable Symptom
[How it manifested: crash, silent wrong output, build failure, test flake, etc.]

### Root Cause
[The technical reason it happened]

### Fix Applied
[What was changed]

### Takeaway
[The rule or pattern that prevents this class of bug in future. Make this specific to this codebase.]
```

---

## Step 4 — Generate GUARDRAILS.md

Mark "Write individual IC cases" as completed. Mark "Generate GUARDRAILS.md" as `in_progress`.

Read every `Takeaway` section from Step 3. Group into **8–12 generic, actionable engineering rules**.

Each rule must have:
- A short bold title
- 1–2 sentence rule statement (imperative, actionable)
- A "Never:" line for the most common anti-pattern
- Source IC links: `[IC-NNN](IC-NNN.md)`

Prepend a **Tech Design Checklist** section:
- [ ] Backend/consumer schema sign-off for any new or renamed payload key
- [ ] Cross-platform alignment check (if applicable)
- [ ] All initialization paths covered
- [ ] Any rewrite of a previously-reverted feature must audit the original contract

Write to `docs/issue-cases/GUARDRAILS.md`.

---

## Step 5 — Write the INDEX.md File

Mark "Generate GUARDRAILS.md" as completed. Mark "Write INDEX.md" as `in_progress`.

```
---
name: issue-cases
description: >-
  Historical engineering issue bank — real bugs, crashes, and logic errors
  mined from the git history. Includes a hot zones map and two-axis (Component × Bug Class)
  classification. Read before modifying historically fragile components.
type: reference
---

# Issue Case Bank — {{PROJECT_NAME}}

[1-sentence summary]

## Case Index

| # | Name | Component | Bug Class | Severity | Commit |
|---|------|-----------|-----------|----------|--------|

---

**How to use this file:**
- Check the Hot Zones Map first — it shows which components carry the most historical risk.
- When modifying a component, look up its cases by component name.
- When writing a new async/threading/null-handling pattern, look up cases by bug class.
- Apply each case's Takeaway — it distills the anti-pattern into an actionable rule.

---

## Hot Zones Map

[generated in Step 2]

---

## Bug Class Reference

| Class | What it covers |
|-------|---------------|
| `concurrency` | Race conditions, thread-unsafe shared state, main-thread violations |
| `null-safety` | Nil/null dereferences, missing guards at API boundaries |
| `type-system` | Integer overflow, wrong type assumptions, ABI size differences |
| `logic-error` | Wrong conditions, off-by-one, parameter confusion, silent wrong output |
| `memory-safety` | Use-after-free, retain cycles, buffer overread, dangling pointers |
| `serialization` | Encoding/decoding errors, wrong byte order, format mismatch |
| `state-management` | Singleton misuse, mutable shared state, lifecycle ordering bugs |
| `api-contract` | Violated preconditions, unexpected input, undocumented assumptions |
| `build-pipeline` | Circular dependencies, hardcoded paths, missing task ordering |
| `security-gap` | Detection disabled, validation bypassed, insecure default config |

Add project-specific classes if needed.

[Individual cases follow]
```

---

## Step 5.5 — Dependency audit (mandatory, no user input required)

Mark "Write INDEX.md" as completed. Mark "Dependency audit" as `in_progress`.

Run immediately after INDEX.md is written. Three checks:

**Check 1 — IC → Feature cross-reference**

If `docs/features/INDEX.md` exists: for each IC case, find the matching F-NNN feature by component name. Add a `feature_ref: [F-NNN]` line to the frontmatter of that IC file. If no match is found, leave the field blank and flag it.

**Check 2 — Orphaned IC cases**

Every IC case must be cited in at least one GUARDRAILS rule. List every IC-NNN that does not appear in any `[IC-NNN]` link in GUARDRAILS.md. For each orphan: identify which existing rule its Takeaway belongs to and add the citation, or create a new rule if the Takeaway covers a distinct pattern not yet in GUARDRAILS.

**Check 3 — Hot zone hook coverage**

For every component listed in the Step 2 Hot Zones Map: verify a corresponding `grep -qE` block exists in the pre-edit hook (to be written in Step 7). List any component that is missing a block.

Report:

| Check | Item | Status | Action taken |
|-------|------|--------|--------------|
| IC→Feature | IC-NNN · component | ✅ / ❌ | feature_ref added / no match |
| Orphaned IC | IC-NNN | ✅ / ❌ | cited in GR-XX / new rule added |
| Hook coverage | `component.ext` | ✅ / ❌ | block present / gap noted for Step 7 |

---

## Step 6 — Update CLAUDE.md

Mark "Dependency audit" as completed. Mark "Update CLAUDE.md" as `in_progress`.

Add a "Before Making Code Changes" section using **active language**:

```
## Before Making Code Changes

Before writing any code that touches a component listed in `docs/issue-cases/INDEX.md`:
1. Open `docs/issue-cases/INDEX.md` and find the component in the Hot Zones Map
2. Read each linked IC case — pay attention to the **Takeaway** rule
3. Explicitly state which past issues are relevant and how the new code avoids repeating them

Do this **before writing any code** — not as a post-review step.
The Hot Zones Map in INDEX.md is the authoritative, always-up-to-date source. Do not duplicate it here.
```

---

## Step 7 — Add the pre-edit hook

Mark "Update CLAUDE.md" as completed. Mark "Add pre-edit hook" as `in_progress`.

Create `.claude/hooks/hot-zone-check.sh`:

```bash
#!/bin/bash
# Hot Zone Check — fires before Edit/Write tool calls.

FILE_PATH=$(cat | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('file_path', d.get('path', '')))
except:
    print('')
" 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

MSG=""

# Add one block per hot-zone component (replace HotZoneFile and ComponentName
# with the actual filenames and component names from the Step 2 Hot Zones Map):
if echo "$FILE_PATH" | grep -qE "HotZoneFile\.(clj|java)"; then
  MSG="HOT ZONE — ComponentName: read docs/issue-cases/INDEX.md for relevant cases and apply their Takeaway rules before writing code."
fi

if [ -n "$MSG" ]; then
  echo "$MSG"
fi

exit 0
```

Make executable: `chmod +x .claude/hooks/hot-zone-check.sh`

Register in `.claude/settings.local.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash /absolute/path/to/.claude/hooks/hot-zone-check.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Step 8 — Update persona skills

Mark "Add pre-edit hook" as completed. Mark "Update persona skills" as `in_progress`.

If the project has persona skills (Dave, Bob, Alice), add a reference to the issue bank in their "Reference" section alongside any existing references.

Mark "Update persona skills" as completed.

---

## Severity Definitions

| Severity | Meaning |
|----------|---------|
| CRITICAL | Data corruption, security bypass, crash in production hot path |
| HIGH | Logic error producing wrong output, signing/validation incorrectness |
| MEDIUM | Crash on edge-case input, silent feature disabled, flaky CI |
| LOW | Maintenance, cleanup, non-functional |
| BLOCKER | Build could not complete |
