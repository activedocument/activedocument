# PR #11: Query Refactor - Logical Operators Simplification

**Date:** 2024-05-27
**PR:** https://github.com/activedocument/activedocument/pull/11
**Issue:** https://github.com/activedocument/activedocument/issues/13
**Type:** Breaking change - API cleanup

## Summary

Refactors the query DSL to remove confusing chainable `and`/`or`/`nor` methods in favor of clearer `all_of`/`any_of`/`none_of` methods that take explicit criteria arrays. This PR also introduces the `QueryNormalizer` module to centralize query expression handling.

## Motivation

Mongoid's query DSL had confusing behavior with chainable logical operators:

```ruby
# Mongoid - confusing: what does this actually mean?
Band.where(name: "Tool").or(name: "Deftones").or(name: "A Perfect Circle")

# Did the user want:
# { $or: [{name: "Tool"}, {name: "Deftones"}, {name: "A Perfect Circle"}] }
# Or something else?
```

The chainable nature led to unpredictable query construction, especially when mixing operators. The internal "merge strategies" added complexity without clear user benefit.

## Changes

### Removed Chainable Methods

The following confusing chainable methods were removed:
- `.and(criteria)` - merged criteria unpredictably
- `.or(criteria)` - chainable OR with confusing semantics
- `.nor(criteria)` - chainable NOR with confusing semantics

### New Explicit Methods

```ruby
# All conditions must match ($and)
Band.all_of({ name: "Tool" }, { origin: "Los Angeles" })
# => { $and: [{ name: "Tool" }, { origin: "Los Angeles" }] }

# Any condition matches ($or)
Band.any_of({ name: "Tool" }, { name: "Deftones" })
# => { $or: [{ name: "Tool" }, { name: "Deftones" }] }

# No condition matches ($nor)
Band.none_of({ name: "Tool" }, { name: "Deftones" })
# => { $nor: [{ name: "Tool" }, { name: "Deftones" }] }
```

### Selectable Module Rewrite

The `Selectable` module (`lib/active_document/criteria/queryable/selectable.rb`) was substantially rewritten:

**Key query methods (all in `Selectable`):**

| Method | MongoDB Operator | Description |
|--------|-----------------|-------------|
| `all_of(*criteria)` | `$and` | All conditions must match |
| `any_of(*criteria)` | `$or` | At least one condition must match |
| `none_of(*criteria)` | `$nor` | No conditions may match |
| `not(*criteria)` | `$not`/`$ne` | Negate conditions |
| `where(criterion)` | varies | General entry point for queries |

**Comparison operators:**

| Method | Operator | Example |
|--------|----------|---------|
| `eq(field: value)` | `$eq` | `Band.eq(name: "Tool")` |
| `gt(field: value)` | `$gt` | `Band.gt(members: 3)` |
| `gte(field: value)` | `$gte` | `Band.gte(members: 3)` |
| `lt(field: value)` | `$lt` | `Band.lt(members: 5)` |
| `lte(field: value)` | `$lte` | `Band.lte(members: 5)` |
| `ne(field: value)` | `$ne` | `Band.ne(name: "Tool")` |

**Array operators:**

| Method | Operator | Example |
|--------|----------|---------|
| `any_in(field: [...])` | `$in` | `Band.any_in(name: ["Tool", "Deftones"])` |
| `not_in(field: [...])` | `$nin` | `Band.not_in(name: ["Tool"])` |
| `contains_all(field: [...])` | `$all` | `Band.contains_all(tags: ["rock", "metal"])` |

**Note:** The `all` method was renamed to `contains_all` to avoid conflict with `Enumerable#all?`:

```ruby
def all(*criteria)
  return clone.tap(&:reset_state!) if criteria.empty?
  raise ArgumentError.new('Use #contains_all instead of #all for to match all array values')
end
```

### `all_of` Implementation Details

The `all_of` method intelligently merges conditions:

```ruby
def all_of(*criteria)
  flatten_args(criteria).inject(clone) do |c, new_s|
    new_s = new_s.selector if new_s.is_a?(Selectable)
    normalized = QueryNormalizer.normalize_expr(new_s, negating: negating?)
    normalized.each do |k, v|
      k = k.to_s
      if c.selector[k]
        # Smart merging: if both are operators on same field, merge them
        # e.g., { age: { $gt: 18 } } + { age: { $lt: 65 } }
        # => { age: { $gt: 18, $lt: 65 } }
        if v.is_a?(Hash) &&
           v.length == 1 &&
           (new_k = v.keys.first).start_with?('$') &&
           (existing_kv = c.selector[k]).is_a?(Hash) &&
           !existing_kv.key?(new_k) &&
           existing_kv.keys.all? { |sub_k| sub_k.start_with?('$') }
          merged_v = c.selector[k].merge(v)
          c.selector.store(k, merged_v)
        else
          # Fall back to explicit $and
          c = c.send(:__combine_criteria__, [k => v], '$and')
        end
      else
        c.selector.store(k, v)
      end
    end
    c
  end
end
```

### QueryNormalizer Module

New `QueryNormalizer` module (`lib/active_document/criteria/queryable/query_normalizer.rb`) centralizes query expression handling:

```ruby
module QueryNormalizer
  extend self

  # Normalizes a criteria hash:
  # - Converts symbol keys to strings
  # - Applies negation if needed ($not for hashes/regexps, $ne for scalars)
  # - Returns BSON::Document for indifferent access
  def normalize_expr(expr, negating: false)
    unless expr.is_a?(Hash)
      raise ArgumentError.new('Argument must be a Hash')
    end

    expr = expr.transform_values do |value|
      if negating
        { value.is_a?(Hash) || regexp?(value) ? '$not' : '$ne' => value }
      else
        value
      end
    end

    BSON::Document.new(expr)
  end

  # Expands values to arrays for $in/$nin/$all operators
  def expand_condition_to_array_values(criterion)
    criterion.transform_values { |value| to_array(value) }
  end

  private

  def to_array(object)
    case object
    when Array then object
    when Range then object.to_a
    else [object]
    end
  end
end
```

### Negation Handling

The `not` method handles negation intelligently:

```ruby
def not(*criteria)
  if criteria.empty?
    # No args: set negating flag for next method
    dup.tap { |query| query.negating = true }
  else
    # With args: negate the criteria
    criteria.compact.inject(clone) do |c, new_s|
      new_s = new_s.selector if new_s.is_a?(Selectable)
      QueryNormalizer.normalize_expr(new_s, negating: negating?).each do |k, v|
        k = k.to_s
        if c.selector[k] || k.start_with?('$') || v.is_a?(Hash)
          # Complex case: use $nor
          c = c.send(:__combine_criteria__, [{ '$nor' => [{ k => v }] }], '$and')
        else
          # Simple case: use $ne or $not (for Regexp)
          negated_operator = v.is_a?(Regexp) ? '$not' : '$ne'
          c = c.send(:__override__, { k => v }, negated_operator)
        end
      end
      c
    end
  end
end
```

**Chainable negation:**

```ruby
# Negate the next condition
Band.not.any_in(name: ["Tool", "Deftones"])
# => { name: { $not: { $in: ["Tool", "Deftones"] } } }

# Negate specific criteria
Band.not(name: "Tool")
# => { name: { $ne: "Tool" } }

Band.not(name: /^Tool/)
# => { name: { $not: /^Tool/ } }
```

### Renamed/Aliased Methods

| Old Name | New Name/Alias | Notes |
|----------|----------------|-------|
| `in` | `any_in` / `contains_any` | Avoid Ruby keyword conflict |
| `nin` | `not_in` / `contains_none` | More readable |
| `all` | `contains_all` | Avoid `Enumerable#all?` conflict |

## Files Changed

Key files:
- `lib/active_document/criteria/queryable/selectable.rb` - Major rewrite (~900 lines)
- `lib/active_document/criteria/queryable/query_normalizer.rb` - New module (~95 lines)
- `lib/active_document/criteria/queryable/storable.rb` - Added typecasting
- Extensive spec updates to reflect new API

## Migration Impact

This is a **breaking change**. Users must:

1. Replace `.and(...)` chains with `.all_of(...)`:
   ```ruby
   # Before
   Band.where(name: "Tool").and(origin: "LA")
   # After
   Band.all_of({ name: "Tool" }, { origin: "LA" })
   # Or simply:
   Band.where(name: "Tool", origin: "LA")
   ```

2. Replace `.or(...)` chains with `.any_of(...)`:
   ```ruby
   # Before
   Band.where(name: "Tool").or(name: "Deftones")
   # After
   Band.any_of({ name: "Tool" }, { name: "Deftones" })
   ```

3. Replace `.nor(...)` chains with `.none_of(...)`:
   ```ruby
   # Before
   Band.nor(name: "Tool", name: "Deftones")
   # After
   Band.none_of({ name: "Tool" }, { name: "Deftones" })
   ```

4. Replace `.all(field: [...])` with `.contains_all(field: [...])`:
   ```ruby
   # Before
   Band.all(tags: ["rock", "metal"])
   # After
   Band.contains_all(tags: ["rock", "metal"])
   ```
