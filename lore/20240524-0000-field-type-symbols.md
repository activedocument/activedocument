# PR #7: Field Types as Symbols Instead of Classes

**Date:** 2024-05-24
**PR:** https://github.com/activedocument/activedocument/pull/7
**Related PRs:** #5 (Convert type class to string), #6 (Convert type declarations to symbols)
**Type:** Breaking change - API simplification

## Summary

This PR modernizes field type declarations by allowing symbols instead of class constants. This makes field definitions cleaner and more Ruby-idiomatic, aligning with Rails conventions like ActiveRecord's `attribute :name, :string`.

## Motivation

Mongoid historically required class constants for field types:

```ruby
field :name, type: String
field :count, type: Integer
field :score, type: Float
```

This approach had issues:
- Required autoloading of type classes before they could be referenced
- Made custom type registration awkward (monkey-patching type classes)
- Inconsistent with Rails conventions (e.g., `attribute :name, :string`)
- Verbose and visually noisy in model definitions

## Changes

### New Field Type API

```ruby
# Before (Mongoid)
field :name, type: String
field :count, type: Integer
field :birthday, type: Date
field :price, type: BigDecimal
field :data, type: BSON::Binary

# After (ActiveDocument)
field :name, type: :string
field :count, type: :integer
field :birthday, type: :date
field :price, type: :big_decimal
field :data, type: :binary
```

### FieldTypes Registry

The new `ActiveDocument::Fields::FieldTypes` module (`lib/active_document/fields/field_types.rb`) provides a centralized registry for type mappings:

```ruby
module FieldTypes
  DEFAULT_MAPPING = {
    array: Array,
    bigdecimal: BigDecimal,
    big_decimal: BigDecimal,
    binary: BSON::Binary,
    boolean: ActiveDocument::Boolean,
    bson_object_id: BSON::ObjectId,
    date: Date,
    datetime: DateTime,
    date_time: DateTime,
    double: Float,
    float: Float,
    hash: Hash,
    integer: Integer,
    object: Object,
    range: Range,
    regexp: Regexp,
    set: Set,
    string: String,
    stringified_symbol: ActiveDocument::StringifiedSymbol,
    symbol: Symbol,
    time: Time,
    timestamp: BSON::Timestamp,
    undefined: Object
  }.with_indifferent_access.freeze
end
```

**Key methods:**

- `FieldTypes.get(type)` - Resolves a symbol/string/class to the actual type class
- `FieldTypes.define_type(symbol, klass)` - Register a custom type mapping
- `FieldTypes.mapping` - Access the mutable mapping hash

### Custom Type Registration

Two ways to register custom types:

```ruby
# Via DSL in Fields.configure block
ActiveDocument::Fields.configure do
  type :point, Point
  type :lat_lng, LatLng
end

# Via direct API call
ActiveDocument::Fields::FieldTypes.define_type(:money, Money)
```

### Backwards Compatibility with Deprecation Warning

Class constants still work but emit a deprecation warning:

```ruby
# This still works but logs a warning:
field :name, type: String
# => WARN: Using a Class (String) in the field :type option is deprecated
#    and will be removed in a future major ActiveDocument version.
#    Please use a Symbol (:string) instead.
```

The warning is only emitted once per type class to avoid log spam:

```ruby
def warn_class_type(type)
  type = type.name
  return if warned_class_types.include?(type)

  symbol = type.demodulize.underscore
  ActiveDocument.logger.warn("Using a Class (#{type})...")
  warned_class_types << type
end
```

### Error Handling

New `InvalidFieldTypeDefinition` error for malformed type registrations:

```ruby
# Raises InvalidFieldTypeDefinition
FieldTypes.define_type(123, String)       # symbol must be String or Symbol
FieldTypes.define_type(:foo, "not a class") # klass must be a Module
```

## Architecture Details

### Type Resolution Flow

1. User declares `field :foo, type: :bar`
2. `Fields::ClassMethods#field` calls `get_field_type(field_name, raw_type)`
3. `get_field_type` calls `FieldTypes.get(raw_type)`
4. `FieldTypes.get` returns:
   - For Symbol/String: Looks up in `mapping` hash
   - For Module/Class: Returns directly (with deprecation warning)
   - Returns `nil` if not found (triggers `UnknownFieldType` error)

### Special Handling for Boolean

The legacy `Boolean` constant (which doesn't exist in Ruby) is specially handled:

```ruby
def module_field_type(field_type)
  warn_class_type(field_type)
  return ActiveDocument::Boolean if field_type.to_s == 'Boolean'
  field_type
end
```

## Files Changed

Key changes:
- `lib/active_document/fields.rb` - Updated field macro to accept symbols
- `lib/active_document/fields/field_types.rb` - New registry module (119 lines)
- `lib/active_document/config.rb` - Added `register_type` configuration
- `lib/active_document/errors/invalid_field_type_definition.rb` - New error class

## Migration Impact

| Mongoid (Class) | ActiveDocument (Symbol) |
|-----------------|-------------------------|
| `String` | `:string` |
| `Integer` | `:integer` |
| `Float` | `:float` |
| `Boolean` | `:boolean` |
| `Date` | `:date` |
| `DateTime` | `:datetime` or `:date_time` |
| `Time` | `:time` |
| `BigDecimal` | `:big_decimal` or `:bigdecimal` |
| `Array` | `:array` |
| `Hash` | `:hash` |
| `BSON::ObjectId` | `:bson_object_id` |
| `BSON::Binary` | `:binary` |
| `BSON::Timestamp` | `:timestamp` |
| `Symbol` | `:symbol` |
| `Range` | `:range` |
| `Regexp` | `:regexp` |
| `Set` | `:set` |

- **Backwards compatible**: Class constants still work (with deprecation warning)
- **Forward migration**: Replace `type: String` with `type: :string`
- See `docs/release-notes/migrating-from-mongoid.txt` for full mapping
