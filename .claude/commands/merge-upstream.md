---
description: Merge commits from upstream Mongoid repository one-by-one
---

Merge commits from upstream Mongoid (mongodb/mongoid) into ActiveDocument, one commit at a time.

## Setup (if not already done)
```bash
git remote add upstream https://github.com/mongodb/mongoid.git
git fetch upstream
```

## Process

1. Find the fork point:
```bash
git merge-base master upstream/master
```

2. List commits to merge (chronological order):
```bash
git log --oneline --reverse <fork-point>..upstream/master
```

3. For each commit, merge one at a time:
```bash
git merge <commit-hash> --no-commit
```

4. Resolve conflicts:
   - Files renamed from `mongoid` to `active_document`: Apply changes to the active_document version
   - `Mongoid` -> `ActiveDocument` namespace changes
   - `mongoid` -> `active_document` in requires/paths
   - `MongoidError` -> `BaseError`
   - Keep our docs/ folder (Mongoid removed theirs)
   - Skip files we don't need (sbom.json, MongoDB-specific workflows)

5. After resolving, commit with message format:
```
Merge upstream commit <hash>: <original subject>

Merges mongodb/mongoid@<hash>

<brief description of what the commit does>
```

6. Continue with next commit.

## Conflict Resolution Tips

- `spec/mongoid/*` files: Apply changes to `spec/active_document/*` equivalent, then `git rm spec/mongoid/*`
- `lib/mongoid/*` files: Apply changes to `lib/active_document/*` equivalent
- New error classes: Update namespace from `Mongoid::Errors` to `ActiveDocument::Errors` and add to errors.rb
- Type fields: Use symbol syntax (`:string`, `:integer`) not class syntax (`String`, `Integer`)

## Current Progress

Check merged commits:
```bash
git log --oneline --grep="Merges mongodb/mongoid@" | head -20
```
