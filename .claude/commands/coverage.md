---
description: Run test coverage and improve coverage for identified gaps
---

Steps:
1. Run `COVERAGE=1 bundle exec rspec`
2. Identify files with missing coverage from the output.
3. Add tests for all identified files with missing coverage.
   - Do NOT rerun coverage until you've made an attempt at improving ALL relevant files.
   - If in context of recent work, prioritize files touched in that work.
   - If you find dead code paths (100% sure), remove them.
   - If general coverage request, prioritize files with lowest coverage.
4. Re-run coverage to verify improvements.
5. Repeat until coverage targets are met or no further improvements possible.
