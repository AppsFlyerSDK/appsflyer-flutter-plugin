If $ARGUMENTS is empty, stop and ask:
"Please provide a Notion URL or a path to a local .md file for the tech design.
Example: `/af-ship-from-tech-design https://notion.so/team/my-design`
Example: `/af-ship-from-tech-design docs/tech-designs/my-feature.md`"
Do not proceed until the user provides a URL or path.

Start the delivery workflow using an existing tech design.
The tech design source is: $ARGUMENTS

Invoke the `af-ship-orch` skill now in Tech-Design-Given mode.
It will fetch and save the tech design, then call Alice to run her full challenge agenda,
work with Dave to resolve any issues, then proceed to implementation after your approval.
