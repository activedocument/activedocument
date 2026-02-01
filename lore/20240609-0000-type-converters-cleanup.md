# PR #26: TypeCasting Cleanup - Remove Mongoize Methods

**Date:** 2024-06-09
**PR:** https://github.com/activedocument/activedocument/pull/26
**Related PRs:** #24 (Remove __mongoize_time__)
**Type:** Breaking change - Architecture cleanup

## Summary

Removes legacy `__mongoize_object_id__` and `__evolve_object_id__` monkey patches from core Ruby classes, replacing them with dedicated TypeConverter modules. This continues the effort to reduce global monkey patching and improve code organization.

## Motivation

Mongoid monkey-patched core classes with methods for converting values to MongoDB-compatible formats:

```ruby
# Mongoid monkey patches on String, Array, Hash, Object
String.__mongoize_object_id__
Array.__evolve_object_id__
Hash.__mongoize_object_id__
Object.__evolve_object_id__
```

Problems with this approach:
1. **Global namespace pollution** - Affects all code in the Ruby process, not just ODM code
2. **Hard to test** - Monkey patches persist across test runs, causing isolation issues
3. **Maintenance burden** - Complex extension files scattered across the codebase
4. **Not idiomatic Ruby** - Double-underscore methods are an anti-pattern
5. **Difficult to debug** - Method origin unclear when inspecting objects

## Changes

### Removed Monkey Patches

**From `String`:**
- `__mongoize_object_id__` - Convert string to ObjectId for storage
- `__evolve_object_id__` - Convert string to ObjectId for queries

**From `Array`:**
- `__mongoize_object_id__` - Convert array elements to ObjectIds
- `__evolve_object_id__` - Convert array elements for queries

**From `Hash`:**
- `__mongoize_object_id__` - Handle `{ '$oid' => '...' }` format
- `__evolve_object_id__` - Handle extended JSON format in queries

**From `Object`:**
- `__mongoize_object_id__` - Fallback for arbitrary objects
- `__evolve_object_id__` - Fallback for arbitrary objects

**Also removed:**
- `ActiveDocument::Evolvable` module (no longer needed)

### New TypeConverter Architecture

Introduced `TypeConverters` module (`lib/active_document/type_converters/`) with dedicated converter classes:

```
lib/active_document/type_converters/
├── bson_object_id.rb    # BSON::ObjectId conversion
└── foreign_key.rb       # FK conversion with association context
```

### BsonObjectId Converter

`lib/active_document/type_converters/bson_object_id.rb`:

```ruby
module ActiveDocument
  module TypeConverters
    module BsonObjectId
      extend self

      # Store value in database (no conversion needed for ObjectIds)
      def to_database(value)
        value
      end

      # Cast a value to ObjectId for database storage
      def to_database_cast(value)
        return if value.blank?

        case value
        when BSON::ObjectId
          value
        when String
          cast_string(value)
        when Hash
          cast_hash(value)
        else
          cast_object(value)
        end
      end
      alias_method :to_ruby_cast, :to_database_cast

      # Cast a value to ObjectId for query use
      def to_query_cast(value)
        return ActiveDocument::RawValue(value) if value == ''
        to_database_cast(value)
      end

      private

      def cast_string(value)
        if BSON::ObjectId.legal?(value)
          BSON::ObjectId.from_string(value)
        else
          cast_object(value)
        end
      end

      def cast_hash(value)
        # Handle MongoDB extended JSON format: { '$oid' => '...' }
        if (id = value['$oid']) && BSON::ObjectId.legal?(id)
          BSON::ObjectId.from_string(id)
        else
          cast_object(value)
        end
      end

      def cast_object(value)
        # Return as RawValue to preserve uncastable values
        ActiveDocument::RawValue(value)
      end
    end
  end
end
```

**Key behaviors:**

| Input | Output |
|-------|--------|
| `BSON::ObjectId` | passthrough |
| `"507f1f77bcf86cd799439011"` (24-char hex) | `BSON::ObjectId` |
| `{ '$oid' => '507f1f77bcf86cd799439011' }` | `BSON::ObjectId` |
| `nil` or blank | `nil` |
| Invalid string | `RawValue(value)` |
| Arbitrary object | `RawValue(value)` |

### ForeignKey Converter

`lib/active_document/type_converters/foreign_key.rb`:

```ruby
module ActiveDocument
  module TypeConverters
    module ForeignKey
      extend self

      # Cast value to ObjectId for database storage
      # Handles arrays, hashes, documents, and associations
      def to_database_cast(value)
        return if value.nil? || value == ''

        value = value.to_a if value.is_a?(Set)

        case value
        when Array
          value = value.map! { |v| to_database_cast(v) }
          value.compact!
          value
        when Hash
          if (id = value['$oid']) && BSON::ObjectId.legal?(id)
            BSON::ObjectId.from_string(id)
          else
            value.transform_values! { |v| to_database_cast(v) }
          end
        when String
          if BSON::ObjectId.legal?(value)
            BSON::ObjectId.from_string(value)
          else
            value
          end
        when ActiveDocument::Document,
             ActiveDocument::Association::Referenced::BelongsTo::Proxy
          value._id
        when ActiveDocument::Association::One
          value._target._id
        else
          value
        end
      end
      alias_method :to_ruby_cast, :to_database_cast

      # Cast value for query use (preserves hash operators)
      def to_query_cast(value)
        return value if value == ''

        value = value.to_a if value.is_a?(Set)

        case value
        when Array
          value.map! { |v| to_query_cast(v) }
        when Hash
          if (id = value['$oid']) && BSON::ObjectId.legal?(id)
            BSON::ObjectId.from_string(id)
          else
            # Preserve operators like { '$in' => [...] }
            value.transform_values! { |v| to_query_cast(v) }
          end
        else
          to_database_cast(value)
        end
      end
    end
  end
end
```

**Key behaviors:**

| Input | Output |
|-------|--------|
| `BSON::ObjectId` | passthrough |
| `[id1, id2, id3]` | Array of ObjectIds (compacted) |
| `Set.new([id1, id2])` | Array of ObjectIds |
| `{ '$in' => [id1, id2] }` | Preserved with converted values |
| `{ '$oid' => '...' }` | `BSON::ObjectId` |
| `document` (ActiveDocument::Document) | `document._id` |
| `belongs_to_proxy` | `proxy._id` |
| `has_one_association` | `association._target._id` |

### RawValue Wrapper

When a value cannot be cast, it's wrapped in `RawValue` to preserve it without modification:

```ruby
# In queries, uncastable values are preserved
TypeConverters::BsonObjectId.to_database_cast("not-an-id")
# => RawValue("not-an-id")
```

This allows queries to work with non-ObjectId values when needed, while signaling that no conversion was performed.

### Integration Points

The converters are used in:

**Association::Constrainable:**
```ruby
def convert_to_foreign_key(value)
  TypeConverters::ForeignKey.to_database_cast(value)
end
```

**Fields::ForeignKey:**
```ruby
def mongoize(value)
  TypeConverters::ForeignKey.to_database_cast(value)
end

def evolve(value)
  TypeConverters::ForeignKey.to_query_cast(value)
end
```

### Method Naming Convention

| Method | Purpose | Transforms Values? |
|--------|---------|-------------------|
| `to_database` | Prepare for storage | No (identity) |
| `to_database_cast` | Cast then store | Yes |
| `to_ruby_cast` | Deserialize from DB | Yes (alias of to_database_cast) |
| `to_query_cast` | Prepare for query | Yes (preserves operators) |

## Architecture Benefits

1. **Isolated logic** - Conversion logic in dedicated, testable modules
2. **No namespace pollution** - Core classes remain unmodified
3. **Clear ownership** - Methods belong to ActiveDocument, not Ruby
4. **Explicit behavior** - Call site shows what conversion is happening
5. **Extensible** - Add new converters without touching core classes

## Files Changed

**Deletions:**
- Monkey patch methods removed from extension files:
  - `lib/active_document/extensions/string.rb`
  - `lib/active_document/extensions/array.rb`
  - `lib/active_document/extensions/hash.rb`
  - `lib/active_document/extensions/object.rb`
- `lib/active_document/evolvable.rb` (module no longer needed)

**Additions:**
- `lib/active_document/type_converters/bson_object_id.rb` (~83 lines)
- `lib/active_document/type_converters/foreign_key.rb` (~76 lines)
- Comprehensive specs for new converters

## Migration Impact

**Internal change only** - No public API changes for normal usage.

Users who were (incorrectly) calling the double-underscore methods directly will need to update:

```ruby
# Before (Mongoid - don't do this)
"507f1f77bcf86cd799439011".__mongoize_object_id__

# After (ActiveDocument)
ActiveDocument::TypeConverters::BsonObjectId.to_database_cast("507f1f77bcf86cd799439011")

# Or better, use the field's mongoize method
MyModel.fields['some_id_field'].mongoize("507f1f77bcf86cd799439011")
```

## Future Work

The TypeConverters architecture can be extended to:
- Handle other BSON types (Decimal128, Timestamp)
- Support custom type converters
- Provide type conversion hooks for users
