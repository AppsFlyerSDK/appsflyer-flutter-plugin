If $ARGUMENTS is empty, stop and ask:
"Please provide a Notion URL or a path to a local .md file for the PRD.
Example: `/af-ship-from-prd https://notion.so/team/my-prd`
Example: `/af-ship-from-prd docs/prds/my-feature.md`"
Do not proceed until the user provides a URL or path.

Start the feature delivery workflow using an existing PRD.
The PRD source is: $ARGUMENTS

Invoke the `af-ship-orch` skill now in PRD-Given mode.
It will fetch and save the PRD, then call Alice to challenge it for completeness,
resolve gaps with you, and delegate to Bob/Erin/Dave.
