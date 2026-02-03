# Remove Autosave & Add Inverse Relation Assignment Control

## Summary

This refactor removes autosave behavior from referenced associations and adds explicit control over inverse relation assignment.

## Changes Made

### 1. Removed Autosave for Referenced Associations

**Files deleted:**
- `lib/active_document/association/referenced/auto_save.rb`
- `spec/active_document/association/auto_save_spec.rb`

**Files modified to remove autosave references:**
- `lib/active_document/association/referenced.rb` - removed require
- `lib/active_document/association.rb` - removed `include Referenced::AutoSave`
- `lib/active_document/association/referenced/association.rb` - removed `setup_autosave!`, `enable_autosave!`, made `autosave?` return false
- `lib/active_document/association/options.rb` - removed `enable_autosave!`
- `lib/active_document/association/relatable.rb` - removed `define_autosaver!`
- `lib/active_document/validatable.rb` - removed autosave on validation
- `lib/active_document/attributes/nested.rb` - made `autosave_nested_attributes` a no-op

**Proxy files modified to remove `.save` calls:**
- `lib/active_document/association/referenced/proxy/one.rb`
  - Removed `save_target_if_persistable`, `save_target_if_base_persisted`
  - Removed all `.save` calls in `nullify`, `substitute`
- `lib/active_document/association/referenced/proxy/many.rb`
  - Removed `.save` calls in `<<`, `cascade!`, `save_or_delay`, `substitute_belongs_to_many`

### 2. Removed Bidirectional belongs_to_many

**Rationale:** `belongs_to_many` must now pair with `has_many` (or `inverse_of: nil`). You cannot have `belongs_to_many <-> belongs_to_many` (bidirectional FK arrays on both sides).

**Files modified:**
- `lib/active_document/association/referenced/binding/many_to_many.rb`
  - Removed inverse FK sync from `bind_one` and `unbind_one`
  - Only manages FK array on the belongs_to_many side

### 3. Added Inverse Relation Assignment Control

**New config option:**
```ruby
ActiveDocument.configure do |config|
  config.allow_inverse_relation_assignment = false  # default
end
```

**New error class:**
- `lib/active_document/errors/inverse_relation_assignment_disallowed.rb`

**New instance method:**
- `doc.allow_inverse_relation_assignment!` - enable for specific instance
- `doc.allow_inverse_relation_assignment?` - check if enabled

**Behavior:**
- By default, assigning from the `has_*` (inverse) side raises `InverseRelationAssignmentDisallowed`
- Must use the `belongs_to_*` side which stores the FK
- Can enable inverse assignment via config or per-instance

### 4. Documentation Updates

- `CLAUDE.md` - added to "Differences from Mongoid"
- `README.md` - added "Intentional Differences from Mongoid" section

## Design Rationale

### Why Remove Autosave?

1. **Explicit over implicit**: Users should explicitly call `.save` when they want persistence
2. **Predictable behavior**: No surprises about what gets saved when
3. **Simpler mental model**: FK changes are in-memory until saved
4. **Easier debugging**: Clear control flow for persistence

### Why Control Inverse Assignment?

1. **Clear FK ownership**: The side that stores the FK should be the side that modifies it
2. **Prevent confusion**: `park.dogs << dog` vs `dog.parks << park` - only one stores the FK
3. **Opt-in for legacy behavior**: Can enable if needed for migration

## Migration Guide

### Before (Mongoid/Old ActiveDocument)
```ruby
person.posts << post  # FK on post, implicitly saves post
post.person = person  # Equivalent
```

### After (New ActiveDocument)
```ruby
# Option 1: Use belongs_to side (recommended)
post.person = person  # Sets FK in memory
post.save!            # Persists FK

# Option 2: Enable inverse assignment
person.allow_inverse_relation_assignment!
person.posts << post  # Sets FK in memory on post
post.save!            # Persists FK

# Option 3: Global config (not recommended)
ActiveDocument.allow_inverse_relation_assignment = true
```

## Test Changes

Tests that assign from the `has_*` side need either:
1. Update to assign from `belongs_to_*` side
2. Add `allow_inverse_relation_assignment` macro to context

Example:
```ruby
describe 'has_one assignment' do
  # NOTE: Remove when tests updated to use belongs_to side
  allow_inverse_relation_assignment

  it 'assigns via has_one' do
    person.game = game  # Works with config enabled
  end
end
```

## Future Work

- Update specs to prefer `belongs_to_*` side assignment
- Remove `allow_inverse_relation_assignment` overrides from specs when no longer needed
- Consider deprecation warnings when inverse assignment is used
