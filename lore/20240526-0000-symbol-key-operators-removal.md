# PR #18: Remove Symbol Key Operators and Monkey Patches

**Date:** 2024-05-26
**PR:** https://github.com/activedocument/activedocument/pull/18
**Issue:** https://github.com/activedocument/activedocument/issues/12
**Type:** Breaking change - API cleanup, monkey patch removal

## Summary

Removes Mongoid's symbol-based query operator syntax and associated monkey patches on core Ruby classes. This eliminates a confusing DSL pattern and reduces monkey patching of core classes.

## Motivation

Mongoid extended Ruby's `Symbol` class with methods like `.gt`, `.lt`, `.in`, etc., allowing queries like:

```ruby
# Mongoid - Symbol operator syntax
Band.where(:member_count.gt => 3)
Band.where(:name.in => ["Tool", "Deftones"])
```

This had several issues:
1. **Monkey patches core classes** - Pollutes Symbol's namespace globally
2. **Confusing DSL** - Looks like Ruby syntax but behaves differently
3. **Non-standard** - Not aligned with Arel or other Ruby ORMs
4. **Maintenance burden** - Required complex `Key` and `Expandable` classes

## Changes

### Removed Classes/Modules

- `ActiveDocument::Criteria::Queryable::Key` - Symbol key wrapper class
- `ActiveDocument::Criteria::Queryable::Expandable` - Key expansion module
- `ActiveDocument::Criteria::Queryable::Macroable` - Key macro methods

### Removed Monkey Patches on Core Classes

From `Symbol`:
- `.gt`, `.gte`, `.lt`, `.lte`, `.ne`
- `.in`, `.nin`
- `.elem_match`, `.exists`, `.mod`, `.regex`, `.size`, `.type`
- `.all`, `.within_box`, `.within_circle`, etc.

From `Array`, `Hash`, `Object`, `String`:
- Various `__expand_complex__` and similar methods

### New Query Syntax

Use explicit hash operators instead:

```ruby
# Before (Mongoid symbol operators)
Band.where(:member_count.gt => 3)
Band.where(:name.in => ["Tool", "Deftones"])

# After (ActiveDocument explicit operators)
Band.where(member_count: { '$gt' => 3 })
Band.where(name: { '$in' => ["Tool", "Deftones"] })

# Or use the query methods
Band.gt(member_count: 3)
Band.any_in(name: ["Tool", "Deftones"])
```

### QueryNormalizer Introduction

New `QueryNormalizer` module handles query hash processing without symbol magic:
- Explicit operator handling
- Clear transformation pipeline
- Better debuggability

## Files Changed

Major deletions:
- `lib/active_document/criteria/queryable/key.rb`
- `lib/active_document/criteria/queryable/expandable.rb`
- `lib/active_document/criteria/queryable/macroable.rb`
- Symbol extension methods throughout `extensions/` directory

Key additions:
- `lib/active_document/criteria/queryable/query_normalizer.rb`

## Migration Impact

This is a **breaking change**. Users must:

1. Replace all symbol operator syntax with hash operators:
   - `:field.gt` → `{ '$gt' => value }` or `.gt(field: value)`
   - `:field.in` → `{ '$in' => values }` or `.any_in(field: values)`

2. Remove any code depending on Symbol monkey patches

See `docs/release-notes/migrating-from-mongoid.txt` for full migration guide.
