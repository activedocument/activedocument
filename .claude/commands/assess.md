---
description: Review recent changes and make refactor/cleanup plan
---

Review the recent changes in the thread holistically.

Make a plan to refactor/cleanup to:
- Consolidate code
- Fix implementation inconsistencies
- Fix anything hacky/bloated/redundant
- DRY up code / extract out a common module (do NOT go overboard)
- Remove dead/unused/obsolete code
- Add missing test coverage
- (BUT do NOT go overboard here; focus on obvious problems and obvious wins.)

Write and save the plan summary to the `lore` folder (NOT project root) in Markdown format, filename: "%Y%m%d-%H%M-lowercase-name.md" (include leading zero of %m/%d/%H/etc)
