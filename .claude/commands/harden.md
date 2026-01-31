---
description: Assess and auto-refactor if confident, then re-run tests
---

Steps:
1. Before starting -> If there are uncommitted git changes, ask if I would like to commit
2. Do the Assess command: Review the recent changes in the thread holistically and make a refactor/cleanup plan:
   - Consolidate code
   - Fix implementation inconsistencies
   - Fix anything hacky/bloated/redundant
   - DRY up code / extract out a common module (do NOT go overboard)
   - Remove dead/unused/obsolete code
   - Add missing test coverage
   - (BUT do NOT go overboard here; do not make performative suggestions)

3. Write the plan to the lore folder (filename: "%Y%m%d-%H%M-lowercase-name.md" format with leading zeros)

4. **Always fix these automatically (slam-dunks):**
   - Code duplication (same logic in multiple places)
   - Inconsistent naming (same concept with different names)
   - Unused methods/constants
   - Dead code paths

5. For other opportunities, ask before implementing.

6. After completing refactors -> re-run tests: `bundle exec rspec`
