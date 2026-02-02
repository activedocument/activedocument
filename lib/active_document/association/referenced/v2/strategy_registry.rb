# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module V2
        # Maps association types to their strategy classes.
        # Used by the Association class to configure itself based on type.
        class StrategyRegistry
          # Configuration for belongs_to_one associations
          BELONGS_TO_ONE = {
            foreign_key: ForeignKey::Single,
            cardinality: Cardinality::One,
            binder: Binding::BelongsToOne,
            proxy: Proxy::One,
            eager_loader: Eager::BelongsTo,
            validation_default: false,
            relation_complements: %i[has_many has_one].freeze
          }.freeze

          # Configuration for belongs_to_many associations
          BELONGS_TO_MANY = {
            foreign_key: ForeignKey::Array,
            cardinality: Cardinality::Many,
            binder: Binding::ManyToMany,
            proxy: Proxy::Many,
            eager_loader: Eager::BelongsToMany,
            validation_default: true,
            relation_complements: %i[belongs_to_many has_many has_one].freeze
          }.freeze

          # Configuration for has_one associations
          HAS_ONE = {
            foreign_key: ForeignKey::None,
            cardinality: Cardinality::One,
            binder: Binding::Has,
            proxy: Proxy::One,
            eager_loader: Eager::HasOne,
            validation_default: true,
            relation_complements: %i[belongs_to_one].freeze
          }.freeze

          # Configuration for has_many associations
          HAS_MANY = {
            foreign_key: ForeignKey::None,
            cardinality: Cardinality::Many,
            binder: Binding::Has,
            proxy: Proxy::Many,
            eager_loader: Eager::HasMany,
            validation_default: true,
            relation_complements: %i[belongs_to_one].freeze
          }.freeze

          # All configurations indexed by type
          CONFIGURATIONS = {
            belongs_to_one: BELONGS_TO_ONE,
            belongs_to_many: BELONGS_TO_MANY,
            has_one: HAS_ONE,
            has_many: HAS_MANY
          }.freeze

          class << self
            # Get the configuration for an association type.
            #
            # @param type [Symbol] The association type
            # @return [Hash] The configuration
            # @raise [ArgumentError] If type is unknown
            def [](type)
              CONFIGURATIONS[type] || raise(ArgumentError, "Unknown association type: #{type}")
            end
            alias_method :for, :[]

            # Get the foreign key strategy class for a type.
            #
            # @param type [Symbol] The association type
            # @return [Class] The foreign key strategy class
            def foreign_key_class(type)
              self[type][:foreign_key]
            end

            # Get the cardinality strategy class for a type.
            #
            # @param type [Symbol] The association type
            # @return [Class] The cardinality strategy class
            def cardinality_class(type)
              self[type][:cardinality]
            end

            # Get the binder class for a type.
            #
            # @param type [Symbol] The association type
            # @return [Class] The binder class
            def binder_class(type)
              self[type][:binder]
            end

            # Get the proxy class for a type.
            #
            # @param type [Symbol] The association type
            # @return [Class] The proxy class
            def proxy_class(type)
              self[type][:proxy]
            end

            # Get the eager loader class for a type.
            #
            # @param type [Symbol] The association type
            # @return [Class] The eager loader class
            def eager_loader_class(type)
              self[type][:eager_loader]
            end

            # Get the default validation setting for a type.
            #
            # @param type [Symbol] The association type
            # @return [Boolean] The default validation setting
            def validation_default(type)
              self[type][:validation_default]
            end

            # Get the valid relation complements for a type.
            #
            # @param type [Symbol] The association type
            # @return [Array<Symbol>] The valid complement types
            def relation_complements(type)
              self[type][:relation_complements]
            end
          end
        end
      end
    end
  end
end
