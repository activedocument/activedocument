# V2 Referenced Association System

## Overview

Complete rewrite of ActiveDocument's referenced association system using composition instead of module inclusion. Introduces `belongs_to_one` and `belongs_to_many` macros enabling flexible relationship pairings.

## New Association Types

| Macro | Stores FK | Cardinality | Replaces |
|-------|-----------|-------------|----------|
| `belongs_to_one` | Single ID | One | `belongs_to` |
| `belongs_to_many` | Array of IDs | Many | `has_and_belongs_to_many` |
| `has_one` | None (FK on other side) | One | (unchanged) |
| `has_many` | None (FK on other side) | Many | (unchanged) |

## Valid Pairings

One side MUST be `belongs_to_*`:
- `belongs_to_one ↔ has_one`
- `belongs_to_one ↔ has_many`
- `belongs_to_one ↔ belongs_to_one`
- `belongs_to_many ↔ has_many`
- `belongs_to_many ↔ belongs_to_one`
- `belongs_to_many ↔ belongs_to_many` (bidirectional, auto-sync)

Invalid: `has_* ↔ has_*` (neither stores FK)

## Architecture

### Directory Structure

```
lib/active_document/association/referenced/v2/
├── association.rb              # Unified association class
├── options.rb                  # Options value object
├── strategy_registry.rb        # Maps types to strategy configs
├── foreign_key/
│   ├── base.rb                 # Base FK strategy
│   ├── single.rb               # Stores single ID (belongs_to_one)
│   ├── array.rb                # Stores array of IDs (belongs_to_many)
│   └── none.rb                 # FK on other side (has_one/has_many)
├── cardinality/
│   ├── one.rb                  # Single target
│   └── many.rb                 # Collection target
├── query/
│   └── builder.rb              # Builds criteria
├── binding/
│   ├── base.rb                 # Base binding logic
│   ├── belongs_to_one.rb       # FK on this side, single
│   ├── has.rb                  # FK on other side (has_one/has_many)
│   └── many_to_many.rb         # Arrays on both sides
├── proxy/
│   ├── one.rb                  # Single document proxy
│   └── many.rb                 # Collection proxy
├── eager/
│   ├── belongs_to.rb           # Eager load for belongs_to_one
│   ├── has_one.rb              # Eager load for has_one
│   ├── has_many.rb             # Eager load for has_many
│   └── belongs_to_many.rb      # Eager load for belongs_to_many
└── method_definer.rb           # Generates accessor methods
```

### Composition Pattern

The unified `Association` class uses strategy objects instead of module inclusion:

```ruby
class Association
  attr_reader :foreign_key_strategy    # ForeignKey::Single/Array/None
  attr_reader :cardinality_strategy    # Cardinality::One/Many
  attr_reader :binder_class            # Binding::BelongsToOne/Has/ManyToMany
  attr_reader :proxy_class             # Proxy::One/Many
  attr_reader :eager_loader_class      # Eager::BelongsTo/HasOne/HasMany/BelongsToMany
end
```

### Strategy Registry

Maps association types to their strategy configurations:

```ruby
CONFIGURATIONS = {
  belongs_to_one: {
    foreign_key: ForeignKey::Single,
    cardinality: Cardinality::One,
    binder: Binding::BelongsToOne,
    proxy: Proxy::One,
    eager_loader: Eager::BelongsTo,
    validation_default: false
  },
  belongs_to_many: {
    foreign_key: ForeignKey::Array,
    cardinality: Cardinality::Many,
    binder: Binding::ManyToMany,
    proxy: Proxy::Many,
    eager_loader: Eager::BelongsToMany,
    validation_default: true
  },
  has_one: {
    foreign_key: ForeignKey::None,
    cardinality: Cardinality::One,
    binder: Binding::Has,
    proxy: Proxy::One,
    eager_loader: Eager::HasOne,
    validation_default: true
  },
  has_many: {
    foreign_key: ForeignKey::None,
    cardinality: Cardinality::Many,
    binder: Binding::Has,
    proxy: Proxy::Many,
    eager_loader: Eager::HasMany,
    validation_default: true
  }
}
```

## Key Implementation Details

### Options Value Object

Immutable wrapper for association options with typed accessors:

```ruby
class Options
  attr_reader :raw

  def class_name; @raw[:class_name]; end
  def foreign_key; @raw[:foreign_key]; end
  def primary_key; @raw[:primary_key] || '_id'; end
  def inverse_of; @raw[:inverse_of]; end
  def polymorphic?; !!@raw[:polymorphic]; end
  def autosave?; !!@raw[:autosave]; end
  # ... etc
end
```

### Foreign Key Strategies

- **Single**: Creates Object field, stores single ID, suffix `_id`
- **Array**: Creates Array field, stores array of IDs, suffix `_ids`
- **None**: No field creation, FK is on the related document

### Binding Classes

- **BelongsToOne**: Sets FK on base document, polymorphic type, inverse reference
- **Has**: Sets FK on target document, used for has_one and has_many
- **ManyToMany**: Manages arrays on both sides for belongs_to_many

### Polymorphic Inverse Detection

For polymorphic belongs_to:
```ruby
def polymorphic_inverses(other)
  # Look for has_one/has_many with as: matching our name and class
  matches = other.relations.values.select do |rel|
    rel.as&.to_sym == name.to_sym &&
      rel.relation_class_name == inverse_class_name
  end
  matches.collect(&:name)
end
```

For has_one/has_many with `:as`:
```ruby
def polymorphic_inverses(other)
  return [as_name] if other.nil?  # Return :as when no object
  # Look for belongs_to :as_name, polymorphic: true
  matches = other.relations.values.select do |rel|
    rel.name.to_sym == as_name.to_sym && rel.polymorphic?
  end
  matches.collect(&:name)
end
```

### Autosave Handling

The `enable_autosave!` method allows enabling autosave without mutating options:

```ruby
def enable_autosave!
  return if @autosave_enabled
  @autosave_enabled = true
  ActiveDocument::Association::Referenced::AutoSave.define_autosave!(self)
end
```

## Macros

Updated `lib/active_document/association/macros.rb`:

```ruby
def belongs_to_one(name, options = {}, &block)
  define_v2_association!(name, :belongs_to_one, options, &block)
end
alias_method :belongs_to, :belongs_to_one

def belongs_to_many(name, options = {}, &block)
  define_v2_association!(name, :belongs_to_many, options, &block)
end

def has_one(name, options = {}, &block)
  define_v2_association!(name, :has_one, options, &block)
end

def has_many(name, options = {}, &block)
  define_v2_association!(name, :has_many, options, &block)
end

def has_and_belongs_to_many(name, options = {}, &block)
  ActiveDocument.logger&.warn("DEPRECATION: has_and_belongs_to_many is deprecated...")
  belongs_to_many(name, options, &block)
end
```

## Test Results

All four association spec files pass:

| Spec File | Examples | Failures | Pending |
|-----------|----------|----------|---------|
| belongs_to_spec.rb | 180 | 0 | 4 |
| has_one_spec.rb | 118 | 0 | 4 |
| has_many_spec.rb | 109 | 0 | 4 |
| has_and_belongs_to_many_spec.rb | 97 | 0 | 5 |
| **Total** | **504** | **0** | **17** |

## Known Issues

### HasMany::Enumerable Type Check Delegation

The `HasMany::Enumerable` class has legacy Mongoid behavior that delegates `is_a?` and `kind_of?` to an empty array:

```ruby
def_delegators [], :is_a?, :kind_of?
```

This causes the enumerable to pretend to be an Array for type checking. Tests use behavior-based assertions (`respond_to?`) instead of type checking (`is_a?`).

See `TODOS.md` for future investigation.

## Backwards Compatibility

| Old API | New API | Behavior |
|---------|---------|----------|
| `belongs_to :x` | `belongs_to_one :x` | Identical (alias) |
| `has_one :x` | `has_one :x` | Identical |
| `has_many :x` | `has_many :x` | Identical |
| `has_and_belongs_to_many :x` | `belongs_to_many :x` | Identical + deprecation warning |
| `Model.relations` | `Model.relations` | Same hash structure |
| Generated methods | Generated methods | Same signatures |

## Files Modified

### New Files (v2/)
- `lib/active_document/association/referenced/v2/association.rb`
- `lib/active_document/association/referenced/v2/options.rb`
- `lib/active_document/association/referenced/v2/strategy_registry.rb`
- `lib/active_document/association/referenced/v2/foreign_key/*.rb`
- `lib/active_document/association/referenced/v2/cardinality/*.rb`
- `lib/active_document/association/referenced/v2/binding/*.rb`
- `lib/active_document/association/referenced/v2/proxy/*.rb`
- `lib/active_document/association/referenced/v2/eager/*.rb`
- `lib/active_document/association/referenced/v2/method_definer.rb`
- `lib/active_document/association/referenced/v2/query/builder.rb`

### Modified Files
- `lib/active_document/association/macros.rb` - Added v2 macros
- `lib/active_document/association/options.rb` - Added `enable_autosave!`
- `lib/active_document/attributes/nested.rb` - Use `enable_autosave!`
- `spec/active_document/association/referenced/*_spec.rb` - Updated for v2 API
