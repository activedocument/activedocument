---
description: Run tests and fix all issues/warnings
---

Run tests and fix all issues and warnings (do not suppress them).

Rules:
- Add or update tests when a change introduces a new scenario or behavior.

Order for each changed file:
1. Run the specific scenario by line number: `bundle exec rspec spec/path/to_spec.rb:123`
2. If step 1 passes, run the whole test file: `bundle exec rspec spec/path/to_spec.rb`
3. If step 2 passes, ask whether to run the full suite: `bundle exec rspec`
