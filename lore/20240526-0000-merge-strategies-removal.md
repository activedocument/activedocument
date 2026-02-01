# PR #20: Remove Merge Strategies

**Date:** 2024-05-26
**PR:** https://github.com/activedocument/activedocument/pull/20
**Issue:** https://github.com/activedocument/activedocument/issues/19
**Type:** Breaking change - Complexity reduction

## Summary

Removes Mongoid's "merge strategies" feature, which allowed configurable behavior for how query criteria were combined. This eliminates significant complexity in favor of predictable, standard behavior.

## Motivation

Mongoid allowed users to configure how query conditions merged:

```ruby
Band.override.where(name: "Tool").where(name: "Deftones")  # Replace
Band.intersect.where(name: "Tool").where(name: "Deftones") # $and
Band.union.where(name: "Tool").where(name: "Deftones")     # $or
```

This feature had significant problems:
1. **Complexity** - Required extensive code to track merge modes
2. **Confusion** - Most users didn't understand the modes
3. **Bugs** - Edge cases with nested conditions were error-prone
4. **Maintenance** - Huge maintenance burden for minimal value

## Changes

### Removed Functionality

- `Criteria#override` - Replaced criteria instead of merging
- `Criteria#intersect` - Used `$and` for same-field conditions
- `Criteria#union` - Used `$or` for same-field conditions
- Merge strategy tracking throughout `Mergeable` module

### Simplified Behavior

Now, query conditions always use simple, predictable rules:
- Same field conditions: later value wins (like Hash merge)
- Different fields: both conditions apply
- Explicit `$and`/`$or`/`$nor`: use `all_of`, `any_of`, `none_of`

```ruby
# Simple behavior - later wins
Band.where(name: "Tool").where(name: "Deftones")
# => { name: "Deftones" }

# Explicit AND when needed
Band.all_of([{ name: "Tool" }, { origin: "LA" }])
# => { $and: [{ name: "Tool" }, { origin: "LA" }] }
```

### Code Cleanup

Major deletions from `Mergeable`:
- Strategy tracking state machine
- Strategy-specific merge methods
- Extension methods on Array, Hash, NilClass, Object

### Selectable Simplification

`Selectable` module rewritten with straightforward condition handling:
- `where` simply sets conditions
- Explicit logical operators for complex queries
- No hidden state affecting query construction

## Files Changed

Major deletions (1,785 lines removed):
- `lib/active_document/criteria/queryable/mergeable.rb` (gutted)
- Extension files in `queryable/extensions/`
- Many spec files for removed functionality

Key changes:
- `lib/active_document/criteria/queryable/selectable.rb` - Simplified logic
- `lib/active_document/criteria/queryable/optional.rb` - Cleaned up

## Migration Impact

Users relying on merge strategies must:

1. Remove all `.override`, `.intersect`, `.union` calls
2. Use explicit logical operators when needed:
   - `.all_of([...])` for explicit AND
   - `.any_of([...])` for explicit OR
3. Adjust expectations for same-field conditions (later wins)

This simplification makes query behavior predictable and matches user expectations.
