# Association System Rewrite Plan

## Overview

Full rewrite of ActiveDocument's referenced association system using composition instead of module inclusion. Introduces `belongs_to_one` and `belongs_to_many` macros enabling flexible relationship pairings.

## Background

The current association system suffers from heavy module inclusion ("spaghetti"):
- Metadata classes include: `Relatable` (which includes `Constrainable`, `Options`), `Buildable`
- Proxy classes inherit from `One`/`Many` < `Proxy`, include `Threaded::Lifecycle`, `Marshalable`, `Enumerable`
- Binding classes include `Bindable`
- Dynamic method definition scattered across `Accessors`, `Builders` modules
- 4 association types with lots of duplicated logic

## Key Decisions

- **HABTM**: Keep as deprecated alias to `belongs_to_many` with warning
- **Sync**: Auto-sync both sides for `belongs_to_many ↔ belongs_to_many`
- **Files**: Create new `v2/` directory, swap when stable, then delete old
- **Composition**: Internal private classes (not user-extensible)

## New Association Types

| Macro | Stores FK | Cardinality | Replaces |
|-------|-----------|-------------|----------|
| `belongs_to_one` | Single ID | One | `belongs_to` |
| `belongs_to_many` | Array of IDs | Many | `has_and_belongs_to_many` |
| `has_one` | None (FK on other side) | One | (unchanged) |
| `has_many` | None (FK on other side) | Many | (unchanged) |

## Valid Pairings

One side MUST be `belongs_to_*`:
- `belongs_to_one ↔ has_one` (current belongs_to/has_one)
- `belongs_to_one ↔ has_many` (current belongs_to/has_many)
- `belongs_to_one ↔ belongs_to_one` (self-referential single)
- `belongs_to_many ↔ has_many` (one-sided array)
- `belongs_to_many ↔ belongs_to_one` (array pointing to single)
- `belongs_to_many ↔ belongs_to_many` (bidirectional arrays, like current HABTM)

Invalid: `has_* ↔ has_*` (neither stores FK)

## Architecture

### Directory Structure

```
lib/active_document/association/referenced/v2/
├── association.rb              # Unified association class
├── options.rb                  # Options value object
├── strategy_registry.rb        # Maps types to strategy configs
├── foreign_key/
│   ├── single.rb               # Stores single ID
│   ├── array.rb                # Stores array of IDs
│   └── none.rb                 # FK on other side
├── cardinality/
│   ├── one.rb                  # Single target
│   └── many.rb                 # Collection target
├── query/
│   └── builder.rb              # Builds criteria
├── binding/
│   ├── belongs_to_one.rb       # FK on this side, single
│   ├── has.rb                  # FK on other side
│   └── many_to_many.rb         # Arrays on both sides
├── proxy/
│   ├── one.rb                  # Single document proxy
│   └── many.rb                 # Collection proxy
├── eager/
│   ├── belongs_to.rb
│   ├── has_one.rb
│   ├── has_many.rb
│   └── belongs_to_many.rb
└── method_definer.rb           # Generates accessor methods
```

### Component Responsibilities

**Foreign Key Strategies** (`v2/foreign_key/*.rb`)
- `Single`: `stores_foreign_key? = true`, creates `Object` field, suffix `_id`
- `Array`: `stores_foreign_key? = true`, creates `Array` field, suffix `_ids`
- `None`: `stores_foreign_key? = false`, no field creation

**Cardinality Strategies** (`v2/cardinality/*.rb`)
- `One`: `many? = false`, nested builder is `Nested::One`
- `Many`: `many? = true`, nested builder is `Nested::Many`

**Query Builder** (`v2/query/builder.rb`)
- `criteria_by_primary_key(object)` - for belongs_to
- `criteria_by_foreign_key(base)` - for has_*
- `criteria_by_id_list(base)` - for belongs_to_many
- Handles polymorphic, scope, order

**Binders** (`v2/binding/*.rb`)
- `BelongsToOne`: Sets FK on base, polymorphic type, inverse relation
- `Has`: Sets FK on target, polymorphic type on target
- `ManyToMany`: Manages arrays on both sides, auto-sync

**Proxies** (`v2/proxy/*.rb`)
- `One`: Single doc access, `substitute`, `nullify`
- `Many`: Collection, `<<`, `push`, `concat`, `build`, `create`, `delete`, `clear`, Enumerable

**Eager Loaders** (`v2/eager/*.rb`)
- `BelongsTo`: Group by FK, lookup by PK
- `HasOne`: Group by PK, lookup by FK
- `HasMany`: Group by PK, collect by FK
- `BelongsToMany`: Group by FK array, lookup by PK

### Unified Association Class

```ruby
class Association
  attr_reader :name, :options, :owner_class
  attr_reader :foreign_key_strategy, :cardinality_strategy
  attr_reader :query_builder, :binder, :proxy_class, :eager_loader_class

  def initialize(owner_class, name, type, options = {}, &block)
    @owner_class = owner_class
    @name = name
    @options = Options.new(options)
    configure_strategies!(type)
    create_extension!(&block)
  end

  delegate :stores_foreign_key?, :foreign_key, to: :foreign_key_strategy
  delegate :many?, :one?, to: :cardinality_strategy

  def setup!
    MethodDefiner.new(self).define_all!
    foreign_key_strategy.create_field!(owner_class)
    setup_callbacks!
    self
  end

  def create_relation(owner, target)
    proxy_class.new(owner, target, self)
  end
end
```

### Strategy Registry

```ruby
CONFIGURATIONS = {
  belongs_to_one: {
    foreign_key: ForeignKey::Single,
    cardinality: Cardinality::One,
    binder: Binding::BelongsToOne,
    proxy: Proxy::One,
    eager_loader: Eager::BelongsTo
  },
  belongs_to_many: {
    foreign_key: ForeignKey::Array,
    cardinality: Cardinality::Many,
    binder: Binding::ManyToMany,
    proxy: Proxy::Many,
    eager_loader: Eager::BelongsToMany
  },
  has_one: {
    foreign_key: ForeignKey::None,
    cardinality: Cardinality::One,
    binder: Binding::Has,
    proxy: Proxy::One,
    eager_loader: Eager::HasOne
  },
  has_many: {
    foreign_key: ForeignKey::None,
    cardinality: Cardinality::Many,
    binder: Binding::Has,
    proxy: Proxy::Many,
    eager_loader: Eager::HasMany
  }
}
```

## Generated Methods

For `belongs_to_one` / `has_one`:
- `name` - getter
- `name=` - setter
- `name?`, `has_name?` - existence
- `build_name` - builder
- `create_name` - creator
- `name_id` / `name_id=` - ID access (belongs_to_one only)

For `belongs_to_many` / `has_many`:
- `name` - getter (returns proxy)
- `name=` - setter (replaces collection)
- `name?`, `has_name?` - existence
- `name_ids` / `name_ids=` - ID array access
- Proxy provides: `build`, `create`, `<<`, `delete`, etc.

## Backwards Compatibility

| Old API | New API | Behavior |
|---------|---------|----------|
| `belongs_to :x` | `belongs_to_one :x` | Identical (alias) |
| `has_one :x` | `has_one :x` | Identical |
| `has_many :x` | `has_many :x` | Identical |
| `has_and_belongs_to_many :x` | `belongs_to_many :x` | Identical + deprecation warning |
| `Model.relations` | `Model.relations` | Same hash structure |
| Generated methods | Generated methods | Same signatures |

## Implementation Phases

1. Create v2 directory structure
2. Implement Options value object
3. Implement ForeignKey strategies (Single, Array, None)
4. Implement Cardinality strategies (One, Many)
5. Implement QueryBuilder
6. Implement Binding classes (BelongsToOne, Has, ManyToMany)
7. Implement Proxy classes (One, Many)
8. Implement EagerLoader classes
9. Implement MethodDefiner
10. Implement unified Association class
11. Implement StrategyRegistry
12. Update macros.rb with new macros
13. Write unit tests for v2 components
14. Run existing test suite and fix failures
15. Switchover: Update MACRO_MAPPING, move v2 to primary, delete old

## Success Criteria

1. All existing tests pass without modification (except for deprecation warning tests)
2. New `belongs_to_one` and `belongs_to_many` macros work
3. All valid pairings work correctly
4. HABTM emits deprecation warning but works identically
5. No performance regression
6. Clean, maintainable codebase with composition
