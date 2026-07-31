---
name: grill-me-aron
description: Relentless interview asking every frontier question at once, round by round.
disable-model-invocation: true
---

Interview user relentlessly until reach shared understanding. Map this as **design tree**: every decision branches into related decisions.

Work tree in **rounds**. **Frontier** is every decision without settled prerequisites — ask only questions you can ask without guessing missing information.
Ask whole frontier in 1 round.
Write 1 html doc with all questions.
Use `assets/round-template.html` as exact document shell. Replace every `{{PLACEHOLDER}}`; repeat documented question fieldset. Preserve CSS, accessibility structure, summary JS, and dependency-free single-file output. Save generated round beside working context unless user specifies path. `assets/reference-round.html` is reference output.
For each question : Present question, from 1 to 4 recommended answers from best to worst. Answers are checkbox. Under, have textarea "precisions".
At end doc, add copy summary button => copy in clipboard summary of all selected answers and related "precisions".
User can choose not to select anything, textarea act as custom answer.
Html doc must emphasis human readability. Heavy use of styling and graphs. Default to dark mode.

Wait for user answers all questions before next round.

Each round user answers reshapes tree — settled decisions push frontier outward and unblock questions that depended on them.
Recompute frontier and ask the next round.
Questions whose answer depends on another still open question belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's.
When frontier question needs fact from the environment (filesystem, tools, etc.), dispatch sub-agent to find it — don't ask user for anything you could look up yourself.
Don't block on it: running exploration is unsettled prerequisite. Only questions downstream wait for sub-agent to report — ask rest of frontier now.
_Decisions_ are user's — put each to them and wait.

Session done when frontier empty: every branch of design tree visited, nothing left silently assumed.
Do not act on it until user confirms you have reached shared understanding.
