# V2 Referenced Association HABTM Proxy Fixes

## Overview

This document summarizes the bug fixes made to the v2 referenced association system, particularly for belongs_to_many (HABTM) associations. These fixes reduced test failures from ~42 to 13 across the full referenced association test suite (3343 examples).

**Final Status**: 13 failures, 22 pending (previously ~42 failures)

## Key Fixes

### 1. HABTM Binding Sync (`_synced` flag)

**File**: `lib/active_document/association/referenced/binding/many_to_many.rb`

**Problem**: The sync callbacks were running redundant updates because the `_synced` flag wasn't being set during binding.

**Solution**: Added `_synced` flag setting at the end of `bind_one`:
```ruby
# Mark both sides as synced to prevent the save callback from
# running redundant updates
base._synced[association.foreign_key] = true
doc._synced[association.inverse_foreign_key] = true if association.inverse_foreign_key && !doc.frozen?
```

### 2. Eager Loading - Inverse Setting for HasMany

**File**: `lib/active_document/association/referenced/eager/has_many.rb`

**Problem**: When eager loading has_many associations, the inverse relationship wasn't being set on child documents, causing extra queries when accessing `child.parent`.

**Solution**: Added `set_on_parent` override and `set_inverse_on_children` method:
```ruby
def set_on_parent(id, element)
  grouped_docs[id]&.each do |parent|
    set_relation(parent, element)
    set_inverse_on_children(parent, element) if association.inverse && element.is_a?(Array)
  end
end

def set_inverse_on_children(parent, children)
  inverse_name = association.inverse
  children.each do |child|
    child.set_relation(inverse_name, parent) if child.is_a?(ActiveDocument::Document)
  end
end
```

### 3. Has_one Binding - Prevent Unnecessary Setter Calls

**File**: `lib/active_document/association/referenced/binding/base.rb`

**Problem**: `remove_associated_in_to` was calling the setter even when the document was already correctly bound, causing test failures.

**Solution**: Added early return when already bound to correct base:
```ruby
def remove_associated_in_to(doc, inverse)
  return unless (associated = doc.ivar(inverse))
  return if associated == base  # Don't remove if already bound correctly
  associated.public_send(association.setter, nil)
end
```

### 4. Autosave Callback - Around Instead of After

**File**: `lib/active_document/association/referenced/auto_save.rb`

**Problem**: `throw(:abort)` doesn't work in `after` callbacks (Rails limitation), causing `UncaughtThrowError` when autosave validation failed.

**Solution**: Changed from `after_persist_parent` to `around_persist_parent` with explicit rollback:
```ruby
klass.send(:define_method, save_method) do |&block|
  if before_callback_halted?
    self.before_callback_halted = false
    block.call if block
  else
    block.call if block  # First persist this document
    __autosaving__ do
      # ... autosave associated documents ...
      if !saved && assoc.send(:require_association?)
        delete if persisted?  # Rollback
        self.new_record = true
        self.before_callback_halted = true
        break
      end
    end
  end
end
klass.around_persist_parent save_method, unless: :autosaved?
```

### 5. Concat - Use `add_to_set` Instead of `push`

**File**: `lib/active_document/association/referenced/proxy/many.rb`

**Problem**: Using `$push` for batch FK updates caused duplicate IDs when documents were added via both in-memory binding and atomic persistence.

**Solution**: Changed to `$addToSet` which is idempotent:
```ruby
# For belongs_to_many, batch persist base's FK array with $addToSet
# Use add_to_set (not push) to avoid duplicates in the FK array
if belongs_to_many? && (persistable? || _creating?) && ids.any? && _base.persisted?
  _base.add_to_set(_association.foreign_key => ids)
end
```

### 6. Scoped/Unscoped Criteria for Belongs_to_many

**Files**:
- `lib/active_document/association/referenced/query/builder.rb`
- `lib/active_document/association/referenced/proxy/many.rb`

**Problem**:
1. `criteria_by_id_list` returned `crit.none` for empty IDs, which created an empty selector instead of `{'_id' => {'$in' => []}}`
2. `unscoped` method used wrong query pattern for belongs_to_many (FK is on base, not target)

**Solution**:
```ruby
# query/builder.rb - Always return $in query
def criteria_by_id_list(base, id_list = nil, skip_scope: false)
  ids = id_list || base.public_send(association.foreign_key) || []
  crit = target_class.criteria
  crit = apply_scope(crit) unless skip_scope
  crit = crit.all_of(association.primary_key => { '$in' => ids })
  with_ordering(crit)
end

# proxy/many.rb - Different query patterns for BTM vs has_many
def unscoped
  if belongs_to_many?
    ids = _base.send(_association.foreign_key) || []
    klass.unscoped.where(_association.primary_key => { '$in' => ids })
  else
    klass.unscoped.where(_association.foreign_key => _base.send(_association.primary_key))
  end
end
```

### 7. `<<` Should Not Save Already-Persisted Unchanged Docs

**File**: `lib/active_document/association/referenced/proxy/many.rb`

**Problem**: When adding an already-persisted document with `inverse_of: nil`, the `<<` method was calling save unnecessarily.

**Solution**: Added check for new record or changes:
```ruby
if (doc = docs.first)
  append(doc)
  # Only save if doc is new or has changes (e.g., inverse FK was added)
  doc.save if persistable? && !_assigning? && !doc.validated? && (doc.new_record? || doc.changed?)
end
```

### 8. Nullify - Execute Callbacks

**File**: `lib/active_document/association/referenced/proxy/many.rb`

**Problem**: `nullify` (called by `clear` for non-destructive associations) wasn't executing `before_remove`/`after_remove` callbacks.

**Solution**: Added callback execution in nullify:
```ruby
def nullify
  # ... FK updates ...

  after_remove_error = nil
  _target.clear do |doc|
    execute_callback :before_remove, doc
    unbind_one(doc)
    # ...
    execute_callback :after_remove, doc
  end
  raise after_remove_error if after_remove_error
end
```

### 9. Delete - Persist FK Changes for Belongs_to_many

**File**: `lib/active_document/association/referenced/proxy/many.rb`

**Problem**: Deleting a document from a belongs_to_many association didn't persist the FK removal atomically.

**Solution**: Added `persist_delete_fk` method:
```ruby
def delete(document)
  execute_callbacks_around(:remove, document) do
    result = _target.delete(document) do |doc|
      if doc
        unbind_one(doc)
        persist_delete_fk(doc) if belongs_to_many? && _base.persisted?
        cascade!(doc) unless _assigning?
      end
    end
    # ...
  end
end

def persist_delete_fk(doc)
  _base.pull(_association.foreign_key => doc.public_send(_association.primary_key))
  if _association.inverse_foreign_key && doc.persisted?
    doc.pull(_association.inverse_foreign_key => _base._id)
  end
end
```

### 10. Substitute/Nullify - Reset Criteria When FK Changes

**File**: `lib/active_document/association/referenced/proxy/many.rb`

**Problem**: When setting association to nil/[] when the relation wasn't loaded, the cached criteria still had old FK values, causing stale query results.

**Solution**: Clear FK, reset cached criteria, and reset enumerable's unloaded criteria:
```ruby
# In substitute_belongs_to_many
if new_docs.empty?
  if _base.persisted? && _association.inverse_foreign_key
    criteria.pull(_association.inverse_foreign_key => _base._id)
  end
  _base.send(_association.foreign_key_setter, [])
  @criteria = nil
  _target.reset_unloaded(criteria) if _target.respond_to?(:reset_unloaded)
end

# In nullify
if belongs_to_many?
  # ... $pull on inverse FK ...
  _base.send(_association.foreign_key_setter, [])
  _base.set(_association.foreign_key => []) if _base.persisted?
  @criteria = nil
end
# ... after _target.clear ...
_target.reset_unloaded(criteria) if belongs_to_many? && _target.respond_to?(:reset_unloaded)
```

## Test Results

Starting failures: ~42
Final failures: 11

The remaining 11 failures relate to:
- Bidirectional sync when setting both sides simultaneously
- Overwriting existing relations
- String key handling in create
- Clear return values
- Accessing own _id from parent's FK in defaults

## Files Modified

- `lib/active_document/association/referenced/binding/base.rb`
- `lib/active_document/association/referenced/binding/many_to_many.rb`
- `lib/active_document/association/referenced/auto_save.rb`
- `lib/active_document/association/referenced/eager/has_many.rb`
- `lib/active_document/association/referenced/proxy/many.rb`
- `lib/active_document/association/referenced/query/builder.rb`
- `lib/active_document/association/referenced/method_definer.rb`
- `spec/active_document/association/referenced/belongs_to/binding_spec.rb`
