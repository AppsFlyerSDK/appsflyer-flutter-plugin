Generate an interactive HTML quiz from a tech design document.

## Step 1 — Resolve the document

**If $ARGUMENTS is empty:**
List all `.md` files in `internal-docs/tech-designs/`.
- If files exist, list them and ask:
  "Which tech design should I quiz you on? (Reply with the number or filename)
  Or reply **project** to generate a quiz covering the whole project from the feature catalog."
  Wait for the user's selection before continuing.
- If the folder does not exist or is empty, ask:
  "No tech designs found in `internal-docs/tech-designs/`. What would you like to do?
  1. Provide a path or Notion URL (reply with the path/URL)
  2. Generate a project quiz from the feature catalog (reply **project**)"
  Wait for the user's reply before continuing.

**If the user replies `project` (or $ARGUMENTS is `project`):**
Check whether `internal-docs/features/INDEX.md` exists.
- If it does not exist, stop and say:
  "No feature catalog found. Run `/af-generate-feature-catalog` first to build `internal-docs/features/`, then try again."
- If it exists, read `internal-docs/features/INDEX.md` to get the full list of features, then read each individual `internal-docs/features/F-*.md` file.
  Set `<slug>` to `project` and `<title>` to the project name derived from `INDEX.md` (e.g. `MyProject — Project Quiz`).
  Proceed to Step 3 in **project mode** (random 10 questions across all features).

**If $ARGUMENTS is provided (and not `project`):**
- Starts with `http` → fetch using the `notion-fetch` MCP tool.
- Otherwise → read the file at the given path directly.

## Step 2 — Derive the feature slug and title

From the document title or filename, derive:
- `<slug>` — kebab-case short name (e.g. `sharedprefs-encryption`)
- `<title>` — human-readable title for display (e.g. `SharedPreferences Encryption`)

## Step 3 — Generate 10 quiz questions

Read the resolved document(s) in full. Generate exactly 10 questions as a JSON array
using this exact structure:

```json
[
  {
    "q": "Question text",
    "opts": ["Option A", "Option B", "Option C", "Option D"],
    "ans": 2,
    "exp": "One-sentence explanation of why the correct answer is correct."
  }
]
```

- `ans` is the zero-based index of the correct option (0–3).
- Every question must have exactly 4 options.

### Answer position distribution

Before writing the JSON, randomly assign a correct answer position (0–3) for
each of the 10 questions. No single index may appear more than 3 times across
the set, ensuring the correct answers are spread across A, B, C, and D.

For each question, place the correct option at its assigned position and fill
the remaining slots with distractors. Set `ans` to match.

Never write all questions with the correct answer at index 0 — this is the
natural default when drafting distractors after the correct answer, and it
must be explicitly overridden.

### What to quiz on

**Tech design mode** — focus on:
- Business problem and motivation — why this feature exists
- Customer or user impact — who benefits and how
- Product goals and success criteria — what done looks like
- Scope and non-goals — what is in vs out
- Key decisions and tradeoffs — why the chosen approach over alternatives
- Risks and mitigations — what could go wrong and how it is handled
- Integration and rollout — how this lands in the product

**Project mode** — pick 10 questions randomly across all features, covering:
- What a feature does and why it exists (Business Purpose)
- What the product loses if a feature is removed
- How features depend on or interact with each other
- What triggers a feature and what it produces
- Known limitations or platform gaps
- Ensure broad spread: do not pick more than 2 questions from the same feature

### What NOT to quiz on

- Exact field names, formula strings, or API parameter names
- Specific numeric constants or thresholds (unless they represent a product decision)
- Low-level implementation details only the author would know
- Trivia answerable by ctrl+F rather than understanding

## Step 4 — Build the output file

Read the template from `templates/af-tech-quiz-template.html`.

Replace both placeholders:
- `{{QUIZ_TITLE}}` → the human-readable title from Step 2 (appears twice: in <title> and in JS)
- `{{QUESTIONS_JSON}}` → the full JSON array from Step 3 (no trailing semicolon — the template already has one)

Create the output directory if it does not exist:
```bash
mkdir -p output.af-tech-quiz
```

Write the result to `output.af-tech-quiz/af-tech-quiz-<slug>.html`.

## Step 5 — Open in browser

Run:
```bash
open output.af-tech-quiz/af-tech-quiz-<slug>.html
```

Then tell the user: "Quiz saved to `output.af-tech-quiz/af-tech-quiz-<slug>.html` and opened in your browser."
