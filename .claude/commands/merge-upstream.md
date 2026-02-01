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

Unless the user specifies a branch, merge from the upstream/master branch.
Do NOT get distracted and merging from branches which you weren't asked.

If the user asks to stop/pause, don't automatically revert in-progress work.
Ask how to proceed--especially if the working directory is messy or you're mid-conflict resolution.

1. Find the fork point:
```bash
git merge-base master upstream/master
```

2. List commits to merge (chronological order):
```bash
git log --oneline --reverse <fork-point>..upstream/master
```

3. **CRITICAL: Actually merge each commit** (not cherry-pick, not manually apply):
```bash
git merge <commit-hash> --no-commit
```

**MANDATORY**: You MUST use `git merge <commit-hash>` for EVERY commit. This is NON-NEGOTIABLE.
- DO NOT manually read and apply changes from upstream commits
- DO NOT cherry-pick commits
- DO NOT copy code from upstream without running `git merge`
- ALWAYS run `git merge <hash> --no-commit` which actually merges the commit into the working tree

The `git merge` command will:
- Pull in all changes from the upstream commit
- Show conflicts where our code differs
- Preserve proper merge history
- Ensure no changes are missed

If you "simulate" a merge by reading upstream code and manually applying it, you WILL miss changes and create subtle bugs. ALWAYS let git do the merge.

4. Review the commit. BE SKEPTICAL.
   - If the commit looks like a feature we shouldn't merge -> stop and ASK before continuing.
   - Assume we cannot trust MongoDB team (upstream Mongoid maintainers) to make good changes;
     many of their commits pointless meddling and breaking changes, bordering on malice.

5. Resolve conflicts:
   - Files renamed from `mongoid` to `active_document`: Apply changes to the active_document version
   - `Mongoid` -> `ActiveDocument` namespace changes
   - `mongoid` -> `active_document` in requires/paths
   - `MongoidError` -> `BaseError`
   - Keep our docs/ folder (Mongoid removed theirs)
   - Skip files we don't need (sbom.json, MongoDB-specific workflows)

6. Re-read the original upstream commit `git show xxx --stat` and compare it to your
   conflict-resolved code. Correct anything you missed.

7. Commit your final code with message format:
```
Merge upstream commit <hash>: <original subject>

Merges mongodb/mongoid@<hash>
MONGOID-<ticket number>
PR#<pr number>

<brief description of what the commit does>
```

8. If you're running low on context (<15%) -> /compact the conversation.

9. Continue with next commit.

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
