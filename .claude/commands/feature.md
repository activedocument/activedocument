---
description: Full feature workflow - assess, implement, harden, test, lint
---

Feature: $ARGUMENTS

Steps:
1. **Assess** - Analyze what's needed:
   - Review codebase for relevant existing code
   - Identify files to create/modify
   - Ask clarifying questions if requirements unclear
   - Create checklist of implementation tasks

2. **Lore** - Write assessment to lore folder ("%Y%m%d-%H%M-feature-name.md")

3. **Implement** - Build the feature:
   - Follow checklist from assessment
   - Write tests alongside implementation
   - Mark tasks complete as you go

4. **Harden** - Review and refine:
   - Assess implementation for issues
   - If 95%+ confident fixes are slam-dunks, apply them
   - Otherwise ask before refactoring

5. **Test** - `bundle exec rspec` - fix all failures/warnings

6. **Lint** - `bundle exec rubocop -A` - fix all issues

7. **Lore** - Update lore file with implementation details and any harden changes
