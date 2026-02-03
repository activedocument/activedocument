# TODOs for Investigation

## HasMany::Enumerable weird is_a?/kind_of? delegation

The `HasMany::Enumerable` class has weird delegation of `is_a?`/`kind_of?` to an empty array - legacy Mongoid behavior from line 22 of `lib/active_document/association/referenced/has_many/enumerable.rb`:

```ruby
def_delegators [], :is_a?, :kind_of?
```

This causes the enumerable to pretend to be an Array for type checking purposes. When checking if a proxy is an instance of a certain class, the type check can fail because these methods are delegated to the internal enumerable target.

This is why we had to use behavior-based testing (`respond_to?`) instead of type checking (`is_a?`) in the `create_relation` specs for `has_many` and `has_and_belongs_to_many` associations.

Consider removing this weird delegation in a future refactor.

# This stuff seems messy

lib/active_document/association/referenced/v2/association.rb

+          # The options wrapper (for code that needs to inspect options)
+          attr_reader :options
+
         # @param owner_class [Class] The class that owns this association
         # @param name [Symbol] The name of the association
         # @param type [Symbol] The association type (:belongs_to_one, :belongs_to_many, :has_one, :has_many)

...
+            @autosave_enabled = false


+          # Whether this association is cyclic.
+          # Referenced associations are never cyclic (only embedded can be).
+          #
+          # @return [false]
+          def cyclic?
+            false
+          end
+
+          # The store_as option (only applies to embedded).
+          #
+          # @return [nil]
+          def store_as
+            nil
+          end
+
+          # The proxy class for this association type.
+          # Compatibility method for code expecting the old API.
+          #
+          # @return [Class]
+          def relation
+            proxy_class
+          end
+
+          # The inverse_of option value.
+          #
+          # @return [Symbol, nil]
+          def inverse_of
+            @options.inverse_of
+          end
+
+          # Returns the autosave setting.
+          # Alias for autosave? for compatibility with old API.
+          #
+          # @return [Boolean]
+          def autosave
+            @options.autosave?
+          end
+