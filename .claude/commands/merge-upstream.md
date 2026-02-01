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

Firstly, if at any point during this process the user asks you to stop/pause, don't
automatically revert in-progress work. If the working dir state is messy, ask the user
how to proceed. If you are in the middle of resolving conflicts, ask user if you should
finish resolving conflicts and pause merge making the merge commit.

Second, avoid cherry-pick and other git actions that don't merge the actual commit history.
If you need to do them tactically to help with complex scenarios in rare cases, it's ok,
but then IMMEDIATELY get back to merging the actual git commits.

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
