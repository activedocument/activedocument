# V2 Association Refactor Plan

## Assessment Summary

Analysis of `lib/active_document/association/referenced/v2/` revealed several refactoring opportunities.

## Slam-Dunk Fixes (Auto-Fix)

### 1. Dead Code Removal

**File:** `lib/active_document/association/referenced/v2/method_definer.rb`
- Remove unused `define_id_getter!` method (lines 116-122)
- Remove unused `define_id_setter!` method (lines 124-131)

These methods are defined but never called - `define_all!` doesn't invoke them.

### 2. Dead Code - Unused Cardinality Method

**File:** `lib/active_document/association/referenced/v2/cardinality/base.rb`
- Remove unused `validation_default` method (line 38)

Validation defaults are determined by `StrategyRegistry.validation_default(association_type)` instead.

### 3. Duplicate Type Resolution Logic

**Files:**
- `lib/active_document/association/referenced/v2/association.rb` lines 670-676 (`resolve_type`)
- `lib/active_document/association/referenced/v2/query/builder.rb` lines 73-81 (`resolve_class`)

Both have identical logic. Consolidate to use one implementation.

## Opportunities for Review (Ask First)

### 4. Code Duplication - Foreign Key Default Calculation

**Files:**
- `lib/active_document/association/referenced/v2/foreign_key/array.rb` lines 58-72
- `lib/active_document/association/referenced/v2/foreign_key/none.rb` lines 54-62

Both calculate default foreign key names using the same pattern. Could extract to `ForeignKey::Base`.

### 5. Code Duplication - Eager Loading Set Relation

**Files:**
- `lib/active_document/association/referenced/v2/eager/belongs_to_many.rb` lines 41-44
- `lib/active_document/association/referenced/v2/eager/has_many.rb` lines 30-33

Both override `set_relation` with identical logic. Could move to `Eager::Base`.

### 6. Inconsistent Binding Parameter

**File:** `lib/active_document/association/referenced/v2/binding/many_to_many.rb`

`ManyToMany#bind_one` has required parameter `(doc)` while `BelongsToOne` and `Has` have `(doc = target)`. Should be consistent.

### 7. Redundant Boolean Coercion

**File:** `lib/active_document/association/referenced/v2/association.rb`

Several places use `!!` for truthiness:
- Line 283: `@polymorphic ||= @options.polymorphic? || !!@options.as`
- Line 381: `@destructive ||= !!(dependent && ...)`

Could simplify to explicit boolean checks.

## Fixes Applied

1. ✅ Remove dead `define_id_getter!` and `define_id_setter!` methods
2. ✅ Remove dead `validation_default` from Cardinality::Base
3. ✅ Consolidate `resolve_type`/`resolve_class` duplication
