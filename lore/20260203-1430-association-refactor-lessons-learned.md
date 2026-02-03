# V2 Association Refactor: Lessons Learned & Hardening Recommendations

## Summary of Fix Categories

Analyzing the diff between `4efb2a7..0a4d637` (12 fix commits post-refactor), the issues fall into these categories:

| Category | Count | Severity |
|----------|-------|----------|
| State synchronization (_synced flags) | 3 | High |
| Criteria caching/invalidation | 3 | High |
| Bidirectional FK persistence | 4 | High |
| Callback ordering/execution | 2 | Medium |
| Missing null context methods | 1 | Medium |
| Return value correctness | 2 | Low |
| Polymorphic inverse lookup | 1 | Medium |

---

## Lessons Learned

### 1. State Synchronization is Non-Trivial

**What went wrong:** The `_synced` flag (which prevents redundant DB updates) wasn't being set during binding operations, causing the sync callbacks to run duplicate updates.

**Root cause:** The binding classes were added as new code without fully understanding the `_synced` mechanism used by the legacy system.

**Lesson:** When refactoring, create explicit documentation of state flags and their invariants. The `_synced` hash is a critical piece of state that must be managed consistently.

**Fix applied:** `binding/many_to_many.rb:32-33` now sets `_synced` for both sides.

---

### 2. Criteria Caching Requires Explicit Invalidation

**What went wrong:** Multiple places cached criteria (e.g., `@criteria` in proxy/many.rb) but didn't invalidate when the underlying FK array changed. This caused stale query results.

**Root cause:** The composition pattern created multiple places that could cache derived state, but no central mechanism to invalidate them.

**Lesson:** Any cached value derived from document state needs invalidation hooks. Consider:
- A `reset_caches` method called on FK changes
- Observer pattern for FK changes
- Lazy computation without caching

**Fixes applied:**
- `proxy/many.rb` now resets `@criteria = nil` when FK changes
- Added `reset_unloaded(criteria)` call to enumerable
- Added `unsynced_base` helper to mark state as dirty

---

### 3. Bidirectional Associations Need Atomic Operations

**What went wrong:** Using `$push` for FK array updates caused duplicates when both in-memory binding AND persistence added the same ID.

**Root cause:** The refactored code didn't account for the race between binding (which modifies in-memory arrays) and persistence (which modifies DB).

**Lesson:** For array FKs, always use idempotent operations:
- Use `$addToSet` instead of `$push` for adds
- Use `$pull` for removes
- Never assume in-memory state matches DB state

**Fix applied:** `proxy/many.rb:430` now uses `add_to_set` instead of `push`.

---

### 4. Callback Ordering Has Rails Semantics

**What went wrong:** Autosave used `after_persist_parent` with `throw(:abort)`, which doesn't work in Rails after callbacks (causes `UncaughtThrowError`).

**Root cause:** The refactor didn't account for Rails callback semantics where `throw(:abort)` only works in before/around callbacks.

**Lesson:** When persisting dependent documents:
- Use `around_` callbacks if you need to halt/rollback
- Never use `throw(:abort)` in `after_` callbacks
- Document the callback chain explicitly

**Fix applied:** `auto_save.rb` now uses `around_persist_parent` with explicit rollback via `delete`.

---

### 5. Eager Loading Must Set Inverse References

**What went wrong:** Eager-loaded has_many children didn't have their inverse (belongs_to) set, causing N+1 queries when accessing `child.parent`.

**Root cause:** The eager loader only set the forward relationship, not the inverse.

**Lesson:** Eager loading should establish the complete bidirectional relationship to prevent lazy-load queries.

**Fix applied:** `eager/has_many.rb` now calls `set_inverse_on_children` to set `child.parent = parent`.

---

### 6. Null Context Must Be Complete

**What went wrong:** `Contextual::None` (returned by `Criteria#none`) was missing `update_all`, `delete_all`, `destroy_all` methods, causing NoMethodError.

**Root cause:** The BTM refactor introduced code paths that called these methods on criteria that could be `none`.

**Lesson:** When adding features that may operate on empty criteria, ensure the null context implements all required methods as no-ops.

**Fix applied:** Added `update_all`, `delete_all`, `destroy_all` to `contextual/none.rb` returning 0.

---

### 7. Polymorphic Lookup Direction Matters

**What went wrong:** `polymorphic_inverses` was looking in the wrong class's relations hash, failing to find the inverse association.

**Root cause:** The lookup for `has_one :x, as: :unit` was searching `other.relations` instead of `relation_class.relations`.

**Lesson:** Polymorphic associations have complex lookup semantics:
- `belongs_to :x, polymorphic: true` → lookup in `other.class`
- `has_one :x, as: :name` → lookup in `relation_class`

**Fix applied:** `association.rb:130` now uses `relation_class.relations` for the `:as` case.

---

## Association State Flags Reference

### Document-Level Flags

#### `_synced` (Hash)
- **Purpose**: Tracks which FK arrays have been persisted to prevent redundant updates
- **Keys**: Foreign key attribute names (e.g., `'trainer_ids'`)
- **Values**: `true` = synced, `false` or missing = needs sync
- **Set by**: Binding classes after successful bind
- **Checked by**: Sync callbacks before running updates
- **Reset by**: Any FK array modification

#### `_building` (Boolean via `_building?`)
- **Purpose**: Skip persistence callbacks during build operations
- **Set by**: `_building { ... }` block
- **Affects**: Auto-save, FK persistence

#### `_assigning` (Boolean via `_assigning?`)
- **Purpose**: Skip persistence during mass assignment
- **Set by**: `_assigning { ... }` block
- **Affects**: Auto-save, FK sync

#### `_creating` (Boolean via `_creating?`)
- **Purpose**: Track create vs update context
- **Affects**: FK array persistence decisions

#### `__autosaving__` (Boolean)
- **Purpose**: Prevent recursive autosave loops
- **Set by**: `__autosaving__ { ... }` block in AutoSave

### Proxy-Level State

#### `@criteria` (Criteria, cached)
- **Purpose**: Cached criteria for querying related documents
- **Invalidated by**: FK array changes
- **Access via**: `criteria` method (lazy builds if nil)

#### `_target` (HasMany::Enumerable or Document)
- **Purpose**: In-memory collection of related documents
- **Has its own**: `unloaded` criteria for lazy loading
- **Reset via**: `reset_unloaded(criteria)`

### State Invariants

1. After `bind_one(doc)`, both `base._synced[fk]` and `doc._synced[inverse_fk]` should be true
2. After modifying FK arrays, `@criteria` must be set to nil
3. `unbind_one` must be the exact inverse of `bind_one`
4. Null context (`Criteria.none`) must implement all query methods

---

## Structural Hardening Recommendations

### A. Add Contract Tests for Strategy Interfaces

**Problem:** The composition pattern (ForeignKey, Cardinality, Binding strategies) lacks explicit interface contracts.

**Recommendation:** Create shared example groups that verify each strategy implements required methods:

```ruby
# spec/support/shared_examples/foreign_key_strategy_spec.rb
shared_examples 'a foreign key strategy' do
  it { is_expected.to respond_to(:stores_foreign_key?) }
  it { is_expected.to respond_to(:foreign_key) }
  it { is_expected.to respond_to(:setup!) }
  # ... etc
end
```

**Files to create:**
- `spec/support/shared_examples/foreign_key_strategy.rb`
- `spec/support/shared_examples/binding_strategy.rb`
- `spec/support/shared_examples/eager_loader_strategy.rb`

---

### B. Add FK Sync Integration Tests

**Problem:** Many bugs were around FK sync edge cases that unit tests didn't catch.

**Recommendation:** Create a comprehensive integration test matrix:

```ruby
# spec/integration/fk_sync_spec.rb
describe 'FK synchronization' do
  context 'belongs_to_many ↔ belongs_to_many' do
    it 'syncs when adding via <<'
    it 'syncs when adding via concat'
    it 'syncs when removing via delete'
    it 'syncs when clearing via nullify'
    it 'syncs when replacing via ='
    it 'handles adding same document twice'
    it 'handles removing non-member document'
  end
  # Repeat for all pairing types
end
```

---

### C. Criteria Lifecycle Hooks

**Problem:** Cached criteria become stale when FK changes.

**Recommendation:** Add a `reset_association_criteria!` method to proxies:

```ruby
def reset_association_criteria!
  @criteria = nil
  _target.reset_unloaded(criteria) if _target.respond_to?(:reset_unloaded)
end
```

Call this from:
- `substitute_belongs_to_many`
- `nullify` (for BTM)
- Any method that modifies the FK array

---

### D. Add Missing Symmetry Tests

**Problem:** Some operations (bind/unbind) aren't tested for symmetry.

**Recommendation:** Add tests verifying:
- `unbind_one(x)` reverses exactly what `bind_one(x)` does
- After `assoc = []`, the association is indistinguishable from never-set
- After `assoc << x; assoc.delete(x)`, state matches original

---

## Files to Create/Modify for Hardening

| File | Action |
|------|--------|
| `spec/support/shared_examples/foreign_key_strategy.rb` | Create |
| `spec/support/shared_examples/binding_strategy.rb` | Create |
| `spec/support/shared_examples/eager_loader_strategy.rb` | Create |
| `spec/integration/referenced_fk_sync_spec.rb` | Create |
| `spec/active_document/association/referenced/foreign_key/*_spec.rb` | Include shared examples |
| `spec/active_document/association/referenced/binding/*_spec.rb` | Include shared examples |
| `spec/active_document/association/referenced/eager/*_spec.rb` | Include shared examples |

---

## Key Guidelines for Future Work

1. **Always use `$addToSet`** (not `$push`) for FK array additions
2. **Always use `$pull`** for FK array removals
3. **Reset `@criteria`** whenever FK arrays change
4. **Set `_synced`** after binding to prevent duplicate updates
5. **Use `around_` callbacks** (not `after_`) when abort/rollback is needed
6. **Test bidirectional symmetry** for all bind/unbind operations
7. **Ensure null contexts** implement all methods that may be called on them
