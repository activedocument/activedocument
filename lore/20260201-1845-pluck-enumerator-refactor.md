# PluckEnumerator: Consolidated Pluck Implementation

## Reason

Upstream Mongoid commit 741ae8b6b (MONGOID-5900, MONGOID-5901) fixed a bug where `#pluck` on associations didn't work correctly. The issue was that calling `person.posts.pluck(:title)` would fail or return incorrect results because associations weren't properly implementing pluck with field demongoization, alias handling, and localized field support.

**Base commit:** `mongodb/mongoid@741ae8b6b` (MONGOID-5900, MONGOID-5901 Fix #pluck on associations)

## Mongoid's Approach: Pluckable Mixin

Mongoid introduced a `Pluckable` module containing instance methods:
- `prepare_pluck` - normalizes field names, builds projection
- `extract_value` - traverses nested fields, handles localization
- `fetch_and_demongoize` - fetches values and converts to Ruby types
- `descend` - navigates nested attribute hashes

This module is mixed into:
- `Mongoid::Contextual::Mongo` - for criteria-based plucking
- `Mongoid::Association::Referenced::HasMany::Enumerable` - for has_many associations

## Alternatives Considered

### Option 1: Port Mongoid's Pluckable mixin directly

**Pros:**
- Minimal divergence from upstream
- Easier to merge future upstream changes

**Cons:**
- Mixin pollution - classes gain internal methods they don't expose publicly
- We already had `PluckEnumerator` for streaming support (`pluck_each`)
- Would need to maintain both `Pluckable` and `PluckEnumerator`

### Option 2: Keep PluckEnumerator, add Pluckable for shared methods

**Pros:**
- Separation of concerns - Pluckable for logic, PluckEnumerator for streaming

**Cons:**
- Two places to look for pluck-related code
- `PluckEnumerator` would need to include `Pluckable` anyway
- More files to maintain

### Option 3: Consolidate everything into PluckEnumerator (chosen)

**Pros:**
- Single source of truth for all pluck logic
- No mixin pollution - consumers call class methods explicitly
- PluckEnumerator instance already exists for streaming
- Clear API: class methods for utilities, instance for enumeration

**Cons:**
- Diverges from upstream structure
- Class methods on an "Enumerator" class is slightly unusual

**Decision:** Option 3. The benefits of consolidation outweigh the minor divergence. The explicit `PluckEnumerator.method(...)` calls are clearer than mixed-in methods appearing magically.

## Implementation

### PluckEnumerator Class Structure

```ruby
class PluckEnumerator
  include Enumerable

  # Class methods - shared utilities
  class << self
    def prepare_pluck(document_class, field_names, prepare_projection: false)
    def pluck_from_documents(document_class, documents, field_names)
    def extract_value(document_class, attrs, field_name)

    private
    def fetch_and_demongoize(obj, key, field)
    def descend(part, current, method_name, field, part_count, is_translation)
  end

  # Instance - streaming enumeration
  def initialize(klass, view, fields)
  def each(&block)  # yields plucked values one at a time
end
```

### Method Signature Choices

We standardized all class methods to take `document_class` as the first positional argument:
- `prepare_pluck(document_class, field_names, ...)`
- `pluck_from_documents(document_class, documents, field_names)`
- `extract_value(document_class, attrs, field_name)`

This differs from Mongoid's approach where `klass` was an instance variable accessed via the mixin.

### Delegation Pattern

Proxies use `def_delegators` for clean forwarding:

```ruby
# HasMany::Proxy - delegates to _target (Enumerable)
def_delegators :_target, :pluck, :pluck_each, ...

# EmbedsMany::Proxy - delegates to criteria
def_delegators :criteria, :find, :pluck, :pluck_each
```

This replaced explicit method definitions that just called through.

## Key Differences from Mongoid

| Aspect | Mongoid | ActiveDocument |
|--------|---------|----------------|
| Structure | `Pluckable` mixin | `PluckEnumerator` class |
| Shared logic | Instance methods via include | Class methods |
| Streaming | No `pluck_each` | `pluck_each` everywhere |
| API consistency | `pluck` only | `pluck` and `pluck_each` on all association types |

## Files Changed

- `lib/active_document/pluck_enumerator.rb` - New location, consolidated class
- `lib/active_document/contextual/mongo/pluck_enumerator.rb` - Deleted (moved)
- `lib/active_document/contextual/mongo.rb` - Updated require, explicit class reference
- `lib/active_document/association/referenced/has_many/enumerable.rb` - Added pluck/pluck_each
- `lib/active_document/association/referenced/has_many/proxy.rb` - Added delegators
- `lib/active_document/association/embedded/embeds_many/proxy.rb` - Added delegators, removed explicit `find`

## Future Enhancements

### RelationPluckEnumerator subclass

The `HasMany::Enumerable#pluck_each` method is complex because it handles three document sources (`_loaded`, `_unloaded`, `_added`). A dedicated `RelationPluckEnumerator` subclass could encapsulate this:

```ruby
class RelationPluckEnumerator < PluckEnumerator
  def initialize(enumerable, fields)
    @enumerable = enumerable
    @fields = fields
  end

  def each(&block)
    # Handle _loaded, _unloaded, _added internally
  end
end
```

This would let `HasMany::Enumerable#pluck_each` become simply:
```ruby
def pluck_each(*keys, &block)
  RelationPluckEnumerator.new(self, keys).each(&block)
end
```

There's a TODO comment in the code noting this possibility.

### Batch processing support

For very large result sets, could add batch processing:
```ruby
pluck_each(:field).each_slice(1000) { |batch| process(batch) }
```

This already works via Enumerable, but explicit batch support in the enumerator could optimize database cursor usage.

### Projection optimization

Currently `prepare_pluck` with `prepare_projection: true` always builds a projection. Could optimize to skip projection when plucking `_id` only (always returned) or when plucking all fields.

## Test Coverage

- `spec/active_document/pluck_enumerator_spec.rb` - 27 direct unit tests
- `spec/active_document/association/referenced/has_many/enumerable_spec.rb` - 677 new lines
- `spec/active_document/association/referenced/has_many/proxy_spec.rb` - 80 new lines
- `spec/active_document/association/embedded/embeds_many/proxy_spec.rb` - 70 new lines

Total: 2831 tests passing.
