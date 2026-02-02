# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module V2
        # Immutable value object wrapping association options.
        # Provides type-safe accessors for all association configuration.
        class Options
          # Options shared by all association types
          SHARED = %i[class_name inverse_of validate extend].freeze

          # Foreign key related options
          FOREIGN_KEY = %i[foreign_key primary_key].freeze

          # Lifecycle options
          DEPENDENT = %i[dependent autosave autobuild].freeze

          # Callback options
          CALLBACKS = %i[before_add after_add before_remove after_remove touch counter_cache].freeze

          # Query options
          QUERYING = %i[order scope].freeze

          # Polymorphic options
          POLYMORPHIC = %i[as polymorphic].freeze

          # belongs_to_many specific options (for bidirectional sync)
          BELONGS_TO_MANY = %i[inverse_foreign_key inverse_primary_key].freeze

          # belongs_to_one specific options
          BELONGS_TO_ONE = %i[optional required].freeze

          # Index option
          INDEX = %i[index].freeze

          # All valid options for belongs_to_one
          BELONGS_TO_ONE_OPTIONS = (
            SHARED + FOREIGN_KEY + DEPENDENT + CALLBACKS + QUERYING +
            POLYMORPHIC + BELONGS_TO_ONE + INDEX
          ).freeze

          # All valid options for belongs_to_many
          BELONGS_TO_MANY_OPTIONS = (
            SHARED + FOREIGN_KEY + DEPENDENT + CALLBACKS + QUERYING +
            BELONGS_TO_MANY + INDEX
          ).freeze

          # All valid options for has_one
          HAS_ONE_OPTIONS = (
            SHARED + FOREIGN_KEY + DEPENDENT + POLYMORPHIC + INDEX
          ).freeze

          # All valid options for has_many
          HAS_MANY_OPTIONS = (
            SHARED + FOREIGN_KEY + DEPENDENT + CALLBACKS + QUERYING +
            POLYMORPHIC + INDEX
          ).freeze

          attr_reader :raw

          # @param hash [Hash] The raw options hash
          def initialize(hash = {})
            @raw = hash.freeze
          end

          # Access raw option value
          # @param key [Symbol] The option key
          # @return [Object] The option value
          def [](key)
            raw[key]
          end

          # Check if option is present
          # @param key [Symbol] The option key
          # @return [Boolean]
          def key?(key)
            raw.key?(key)
          end

          # @return [String, nil] Custom class name for the associated model
          def class_name
            raw[:class_name]
          end

          # @return [Symbol, nil] Explicit inverse association name
          def inverse_of
            raw[:inverse_of]
          end

          # @return [String, nil] Custom foreign key field name
          def foreign_key
            raw[:foreign_key]&.to_s
          end

          # @return [String] Primary key field (defaults to '_id')
          def primary_key
            (raw[:primary_key] || '_id').to_s
          end

          # @return [Symbol, nil] Dependent behavior (:destroy, :delete_all, :nullify, :restrict_with_exception, :restrict_with_error)
          def dependent
            raw[:dependent]
          end

          # @return [Symbol, nil] Polymorphic identifier for has_* associations
          def as
            raw[:as]
          end

          # @return [Boolean] Whether this is a polymorphic belongs_to
          def polymorphic?
            !!raw[:polymorphic]
          end

          # @return [Boolean] Whether to auto-save associated documents
          def autosave?
            !!raw[:autosave]
          end

          # @return [Boolean] Whether to auto-build on access
          def autobuild?
            !!raw[:autobuild]
          end

          # @return [Boolean, nil] Whether to validate associated documents
          def validate
            raw[:validate]
          end

          # @return [Boolean] Whether validate option was explicitly set
          def validate?
            key?(:validate)
          end

          # @return [Hash, nil] Default ordering for collection associations
          def order
            raw[:order]
          end

          # @return [Proc, Symbol, nil] Scope to apply when querying
          def scope
            raw[:scope]
          end

          # @return [Boolean] Whether to create an index on the foreign key
          def indexed?
            !!raw[:index]
          end

          # @return [Boolean, String, Symbol] Touch configuration
          def touch
            raw[:touch]
          end

          # @return [Boolean] Whether touch is enabled
          def touchable?
            !!raw[:touch]
          end

          # @return [String, Symbol, nil] Custom touch field name
          def touch_field
            touch if touch.is_a?(String) || touch.is_a?(Symbol)
          end

          # @return [Boolean, String, Symbol] Counter cache configuration
          def counter_cache
            raw[:counter_cache]
          end

          # @return [Boolean] Whether counter cache is enabled
          def counter_cached?
            !!raw[:counter_cache]
          end

          # @return [Boolean] Whether inverse_of was explicitly set to nil
          def forced_nil_inverse?
            key?(:inverse_of) && !inverse_of
          end

          # @return [Boolean, nil] Whether association is optional (belongs_to_one only)
          def optional
            return raw[:optional] if key?(:optional)
            return !raw[:required] if key?(:required)

            nil
          end

          # @return [Boolean] Whether association is required (belongs_to_one only)
          def required?
            optional == false
          end

          # @return [String, nil] Inverse foreign key field (belongs_to_many only)
          def inverse_foreign_key
            raw[:inverse_foreign_key]&.to_s
          end

          # @return [String, nil] Inverse primary key field (belongs_to_many only)
          def inverse_primary_key
            raw[:inverse_primary_key]&.to_s
          end

          # @return [Module, nil] Extension module
          def extension
            raw[:extend]
          end

          # Callback accessors
          # @return [Array<Proc, Symbol>] Before add callbacks
          def before_add
            Array(raw[:before_add])
          end

          # @return [Array<Proc, Symbol>] After add callbacks
          def after_add
            Array(raw[:after_add])
          end

          # @return [Array<Proc, Symbol>] Before remove callbacks
          def before_remove
            Array(raw[:before_remove])
          end

          # @return [Array<Proc, Symbol>] After remove callbacks
          def after_remove
            Array(raw[:after_remove])
          end

          # Get callbacks by type
          # @param callback_type [Symbol] The callback type
          # @return [Array<Proc, Symbol>] The callbacks
          def get_callbacks(callback_type)
            Array(raw[callback_type])
          end

          # Validate options against allowed list
          # @param association_type [Symbol] The association type
          # @param owner_class [Class] The owning class
          # @param name [Symbol] The association name
          # @raise [Errors::InvalidRelationOption] If invalid option found
          def validate!(association_type, owner_class, name)
            valid_options = valid_options_for(association_type)
            raw.each_key do |opt|
              next if valid_options.include?(opt)

              raise Errors::InvalidRelationOption.new(owner_class, name, opt, valid_options)
            end
          end

          private

          def valid_options_for(association_type)
            case association_type
            when :belongs_to_one then BELONGS_TO_ONE_OPTIONS
            when :belongs_to_many then BELONGS_TO_MANY_OPTIONS
            when :has_one then HAS_ONE_OPTIONS
            when :has_many then HAS_MANY_OPTIONS
            else
              raise ArgumentError, "Unknown association type: #{association_type}"
            end
          end
        end
      end
    end
  end
end
