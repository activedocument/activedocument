---
description: Fix linting issues and warnings
---

Run linters:
```bash
bundle exec rubocop -A
```
This will autocorrect issues. Check any non-autocorrected warnings.

For issues that aren't easily fixed, leave them as-is then run:
```bash
bundle exec rubocop --auto-gen-config --exclude-limit 1000
```

Fix all issues and all warnings in the output (do not suppress them).

Ignore any line-ending (CR-LF) warnings; these are just because we are using a Windows filesystem locally, but Git will handle them when we commit.

After linting is complete, re-run tests if there have been significant changes.
