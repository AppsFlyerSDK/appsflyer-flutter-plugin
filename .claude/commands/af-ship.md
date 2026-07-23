Check $ARGUMENTS for flags before doing anything else:

**If $ARGUMENTS starts with `--prd `:**
Extract the URL or path that follows `--prd `.
If nothing follows `--prd`, stop and ask:
"Please provide a Notion URL or local .md path after --prd
(e.g. `/af-ship --prd https://notion.so/team/my-prd`)."
Do not proceed until a URL or path is provided.
Otherwise: invoke the `af-ship-orch` skill in PRD-Given mode.
The PRD source is the value extracted from $ARGUMENTS after `--prd `.

**If $ARGUMENTS starts with `--tech-design `:**
Extract the URL or path that follows `--tech-design `.
If nothing follows `--tech-design`, stop and ask:
"Please provide a Notion URL or local .md path after --tech-design
(e.g. `/af-ship --tech-design internal-docs/tech-designs/my-feature.md`)."
Do not proceed until a URL or path is provided.
Otherwise: invoke the `af-ship-orch` skill in Tech-Design-Given mode.
The tech design source is the value extracted from $ARGUMENTS after `--tech-design `.

**If $ARGUMENTS starts with `--` (unrecognized flag):**
Stop and ask:
"Unrecognized flag. Supported flags are:
- `--prd <url-or-path>` — start from an existing PRD
- `--tech-design <url-or-path>` — start from an existing tech design
Or provide a feature description directly (e.g. `/af-ship add dark mode`)."
Do not proceed.

**If $ARGUMENTS contains no flags (default — new feature from scratch):**
If $ARGUMENTS is empty or contains only one word, stop and ask:
"What feature would you like to implement? Please give a short description
(e.g. `/af-ship add dark mode to settings screen`)."
Do not proceed until the user provides a description.
Otherwise, start the full feature delivery workflow for the following feature:

$ARGUMENTS

Invoke the `af-ship-orch` skill now to begin. It will set up the workflow tasks,
then hand off to Alice to write a PRD, coordinate research and engineering
through tech design, implementation, and feature documentation.
