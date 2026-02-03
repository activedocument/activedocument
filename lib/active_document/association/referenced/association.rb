# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      # Unified association class for all referenced association types.
      # Uses composition to provide type-specific behavior through strategies.
      class Association
        # Primary key default
        PRIMARY_KEY_DEFAULT = '_id'

        attr_reader :name, :owner_class, :association_type
        attr_reader :foreign_key_strategy, :cardinality_strategy
        attr_reader :binder_class, :proxy_class, :eager_loader_class

        # Module path for resolving class names
        attr_reader :module_path

        # Extension module for this association
        attr_reader :extension

        # The options wrapper (for code that needs to inspect options)
        attr_reader :options

        # For eager loading - stores parent inclusions
        attr_accessor :parent_inclusions

        # @param owner_class [Class] The class that owns this association
        # @param name [Symbol] The name of the association
        # @param type [Symbol] The association type (:belongs_to_one, :belongs_to_many, :has_one, :has_many)
        # @param opts [Hash] Options for the association
        # @param block [Proc] Optional extension block
        def initialize(owner_class, name, type, opts = {}, &block)
          @owner_class = owner_class
          @name = name
          @association_type = type
          @options = Options.new(opts)
          @autosave_enabled = false
          @extension = nil

          @module_path = owner_class.name ? owner_class.name.split('::')[0..-2].join('::') : ''
          @module_path << '::' unless @module_path.empty?

          configure_strategies!
          create_extension!(&block)
          validate_options!
        end

        # Set up the association on the owning class.
        #
        # @return [self]
        def setup!
          MethodDefiner.new(self).define_all!
          foreign_key_strategy.create_field!(owner_class)
          setup_index! if indexed?
          setup_polymorphic! if polymorphic?
          setup_callbacks!
          owner_class.aliased_fields[name.to_s] = foreign_key if stores_foreign_key?
          self
        end

        # Create an association proxy for the owner and target.
        #
        # @param owner [ActiveDocument::Document] The owning document
        # @param target [ActiveDocument::Document, Array] The target document(s)
        # @return [Proxy::Base] The proxy
        def create_relation(owner, target)
          proxy_class.new(owner, target, self)
        end

        # Build target document(s) from raw data.
        #
        # @param base [ActiveDocument::Document] The base document
        # @param object [Object] The object to build from (document, ID, or nil)
        # @param type [Class, nil] The polymorphic type
        # @param selected_fields [Hash, nil] Selected fields
        # @return [ActiveDocument::Document, Array, Criteria, nil]
        def build(base, object, type = nil, selected_fields = nil)
          # If object is a document or array of documents, return directly
          return object if object.is_a?(Document)
          return object if object.is_a?(::Array) && !object.empty? && object.first.is_a?(Document)

          # For has_one/has_many, query related documents (FK on other side)
          unless stores_foreign_key?
            crit = criteria(base)
            return one? ? crit.first : crit
          end

          # For belongs_to_many, always return a criteria
          return criteria(base) if association_type == :belongs_to_many

          # For belongs_to_one, return nil if no object
          return nil if object.nil?

          # For belongs_to_one with an ID, query for the document
          execute_query(object, type)
        end

        # Get criteria for this association.
        #
        # @param base [ActiveDocument::Document] The base document
        # @param id_list [Array, nil] Optional ID list for belongs_to_many
        # @return [ActiveDocument::Criteria]
        def criteria(base, id_list = nil)
          query_builder = Query::Builder.new(self)

          case association_type
          when :belongs_to_one
            query_builder.criteria_by_primary_key(base.send(foreign_key), polymorphic_type(base))
          when :belongs_to_many
            query_builder.criteria_by_id_list(base, id_list)
          when :has_one, :has_many
            query_builder.criteria_by_foreign_key(base)
          end
        end

        # Build criteria for belongs_to_many without applying scope.
        # Used for syncing FK arrays where we need to update all documents in the ID list.
        #
        # @param id_list [Array] The IDs to query for
        # @return [ActiveDocument::Criteria]
        def unscoped_criteria(id_list)
          return relation_class.none if id_list.blank?

          relation_class.criteria.where(primary_key => { '$in' => id_list })
        end

        # == Delegation to strategies ==

        delegate :stores_foreign_key?, :foreign_key, :foreign_key_setter,
                 :foreign_key_check, to: :foreign_key_strategy

        delegate :many?, :one?, :nested_builder_class, to: :cardinality_strategy

        # == Association metadata ==

        # The class name of the related model.
        #
        # @return [String]
        def relation_class_name
          @class_name ||= @options.class_name || ActiveSupport::Inflector.classify(name)
        end
        alias_method :class_name, :relation_class_name

        # The class of the related model.
        #
        # @return [Class]
        def relation_class
          @klass ||= begin
            cls_name = @options.class_name || ActiveSupport::Inflector.classify(name)
            resolve_name(inverse_class, cls_name)
          end
        end
        alias_method :klass, :relation_class

        # The class name of the owning model.
        #
        # @return [String]
        def inverse_class_name
          @inverse_class_name ||= owner_class.name
        end

        # The owning class.
        #
        # @return [Class]
        def inverse_class
          owner_class
        end
        alias_method :inverse_klass, :inverse_class

        # The primary key field name.
        #
        # @return [String]
        def primary_key
          @options.primary_key
        end

        # The explicitly configured foreign key option (if any).
        # Used by ForeignKey strategies to determine the field name.
        #
        # @return [String, nil]
        def foreign_key_option
          @options.foreign_key
        end

        # The setter method name.
        #
        # @return [String]
        def setter
          @setter ||= "#{name}="
        end

        # The inverse setter method name.
        #
        # @param other [Object] Optional context for polymorphic
        # @return [String, nil]
        def inverse_setter(other = nil)
          @inverse_setter ||= "#{inverses(other).first}=" if inverses(other).present?
        end

        # Get the inverse foreign key (for belongs_to_many).
        #
        # @return [String, nil]
        def inverse_foreign_key
          return unless association_type == :belongs_to_many

          @inverse_foreign_key ||= foreign_key_strategy.inverse_foreign_key
        end

        # Get the inverse foreign key setter (for belongs_to_many).
        #
        # @return [String, nil]
        def inverse_foreign_key_setter
          "#{inverse_foreign_key}=" if inverse_foreign_key
        end

        # == Inverse detection ==

        # Get the inverse association names.
        #
        # @param other [Object] Optional context
        # @return [Array<Symbol>]
        def inverses(other = nil)
          return [@options.inverse_of] if @options.inverse_of
          return [] if @options.forced_nil_inverse?

          if polymorphic?
            polymorphic_inverses(other)
          else
            determine_inverses(other)
          end
        end

        # Get the first inverse name.
        #
        # @param other [Object] Optional context
        # @return [Symbol, nil]
        def inverse(other = nil)
          candidates = inverses(other)
          candidates&.detect { |c| c }
        end

        # Get the inverse association metadata.
        #
        # @param other [Object] Optional context
        # @return [Association, nil]
        def inverse_association(other = nil)
          # For polymorphic belongs_to (e.g., belongs_to :unit, polymorphic: true),
          # we need to use 'other' to determine which class to look up the inverse on.
          # For has_one/has_many with :as (polymorphic parent), we use relation_class.
          klass = if polymorphic? && in_to? && other
                    # Polymorphic belongs_to: look up on the other document's class
                    other.class
                  else
                    # Non-polymorphic or has_one/has_many: look up on relation_class
                    relation_class
                  end
          klass.relations[inverse(other)]
        end

        # == Type checking ==

        # Whether this is a belongs_to_* association.
        #
        # @return [Boolean]
        def in_to?
          %i[belongs_to_one belongs_to_many].include?(association_type)
        end

        # Whether this association is embedded (always false for referenced).
        #
        # @return [false]
        def embedded?
          false
        end

        # Whether this association is cyclic.
        # Referenced associations are never cyclic (only embedded can be).
        #
        # @return [false]
        def cyclic?
          false
        end

        # The store_as option (only applies to embedded).
        #
        # @return [nil]
        def store_as
          nil
        end

        # The proxy class for this association type.
        # Compatibility method for code expecting the old API.
        #
        # @return [Class]
        def relation
          proxy_class
        end

        # The inverse_of option value.
        #
        # @return [Symbol, nil]
        def inverse_of
          @options.inverse_of
        end

        # Returns the autosave setting.
        # Alias for autosave? for compatibility with old API.
        #
        # @return [Boolean]
        def autosave
          @options.autosave?
        end

        # == Options ==

        # Whether this association is polymorphic.
        #
        # @return [Boolean]
        def polymorphic?
          @polymorphic ||= @options.polymorphic? || !!@options.as
        end

        # The polymorphic type field name.
        #
        # @return [String, nil]
        def type
          @type ||= "#{@options.as}_type" if @options.as
        end

        # The type setter method name.
        #
        # @return [String, nil]
        def type_setter
          @type_setter ||= "#{type}=" if type
        end

        # The inverse type field name (for polymorphic belongs_to).
        #
        # @return [String, nil]
        def inverse_type
          @inverse_type ||= "#{name}_type" if polymorphic? && association_type == :belongs_to_one
        end

        # The inverse type setter method name.
        #
        # @return [String, nil]
        def inverse_type_setter
          @inverse_type_setter ||= "#{inverse_type}=" if inverse_type
        end

        # Get the resolver for polymorphic associations.
        #
        # @return [ActiveDocument::ModelResolver, nil]
        def resolver
          @resolver ||= ActiveDocument::ModelResolver.resolver(@options[:polymorphic]) if polymorphic?
        end

        # Whether to validate the association.
        #
        # @return [Boolean]
        def validate?
          @validate ||= if @options.validate?
                          !!@options.validate
                        else
                          validation_default
                        end
        end

        # The default validation setting.
        #
        # @return [Boolean]
        def validation_default
          StrategyRegistry.validation_default(association_type)
        end

        # Whether to autosave.
        #
        # @return [Boolean]
        def autosave?
          @autosave_enabled || @options.autosave?
        end

        # Enable autosave for this association (called by accepts_nested_attributes_for).
        #
        # @return [void]
        def enable_autosave!
          return if @autosave_enabled

          @autosave_enabled = true
          ActiveDocument::Association::Referenced::AutoSave.define_autosave!(self)
        end

        # Whether to autobuild.
        #
        # @return [Boolean]
        def autobuilding?
          @options.autobuild?
        end

        # Whether indexed.
        #
        # @return [Boolean]
        def indexed?
          @options.indexed?
        end

        # The dependent option.
        #
        # @return [Symbol, nil]
        def dependent
          @options.dependent
        end

        # Whether destructive dependent.
        #
        # @return [Boolean]
        def destructive?
          @destructive ||= !!(dependent && %i[delete_all destroy].include?(dependent))
        end

        # Whether counter cached.
        #
        # @return [Boolean]
        def counter_cached?
          @options.counter_cached?
        end

        # Whether touchable.
        #
        # @return [Boolean]
        def touchable?
          @options.touchable?
        end

        # The touch field.
        #
        # @return [String, Symbol, nil]
        def touch_field
          @options.touch_field
        end

        # The order option.
        #
        # @return [Hash, nil]
        def order
          @options.order
        end

        # The scope option.
        #
        # @return [Proc, Symbol, nil]
        def scope
          @options.scope
        end

        # The :as option (polymorphic name).
        #
        # @return [Symbol, nil]
        def as
          @options.as
        end

        # The counter cache column name.
        #
        # @return [String]
        def counter_cache_column_name
          @counter_cache_column_name ||= if @options.counter_cache.is_a?(String) ||
                                            @options.counter_cache.is_a?(Symbol)
                                           @options.counter_cache
                                         else
                                           "#{inverse || inverse_class_name.demodulize.underscore.pluralize}_count"
                                         end
        end

        # Get callbacks for a type.
        #
        # @param callback_type [Symbol] The callback type
        # @return [Array<Proc, Symbol>]
        def get_callbacks(callback_type)
          @options.get_callbacks(callback_type)
        end

        # Whether the inverse was forced to nil.
        #
        # @return [Boolean]
        def forced_nil_inverse?
          @options.forced_nil_inverse?
        end

        # Whether this association can bind a document.
        #
        # @param doc [ActiveDocument::Document] The document
        # @return [Boolean]
        def bindable?(doc)
          return true if forced_nil_inverse?

          case association_type
          when :belongs_to_many
            !!inverse && doc.fields.key?(foreign_key)
          when :has_one, :has_many
            # For has_one/has_many, the FK is on the target side
            !!inverse(doc) && doc.fields.key?(foreign_key)
          else
            false
          end
        end

        # The key field for this association.
        #
        # @return [String]
        def key
          stores_foreign_key? ? foreign_key : primary_key
        end

        # Convert the supplied object to the appropriate type to set as the
        # foreign key for an association.
        #
        # @param object [Object] The object to convert.
        # @return [Object] The object cast to the correct type.
        def convert_to_foreign_key(object)
          return convert_polymorphic(object) if polymorphic?

          field = relation_class.fields['_id']
          if relation_class.using_object_ids?
            ActiveDocument::TypeConverters::ForeignKey.to_database_cast(object)
          elsif object.is_a?(::Array)
            object.map! { |obj| field.mongoize(obj) }
          else
            field.mongoize(object)
          end
        end

        # The nested builder.
        #
        # @param attributes [Hash] The attributes
        # @param opts [Hash] Options
        # @return [Nested::One, Nested::Many]
        def nested_builder(attributes, opts)
          nested_builder_class.new(self, attributes, opts)
        end

        # The atomic path calculator.
        #
        # @param document [ActiveDocument::Document] The document
        # @return [ActiveDocument::Atomic::Paths::Root]
        def path(document)
          ActiveDocument::Atomic::Paths::Root.new(document)
        end

        # The relation complements (valid inverse types).
        #
        # @return [Array<Symbol>]
        def relation_complements
          StrategyRegistry.relation_complements(association_type)
        end

        # Equality check.
        #
        # @param other [Object] The other object
        # @return [Boolean]
        def ==(other)
          return false unless other.is_a?(self.class)

          relation_class_name == other.relation_class_name &&
            inverse_class_name == other.inverse_class_name &&
            name == other.name
        end

        private

        def convert_polymorphic(object)
          if object.is_a?(ActiveDocument::Document)
            object._id
          else
            ActiveDocument::TypeConverters::ForeignKey.to_database_cast(object)
          end
        end

        def configure_strategies!
          config = StrategyRegistry.for(association_type)

          @foreign_key_strategy = config[:foreign_key].new(self)
          @cardinality_strategy = config[:cardinality].new(self)
          @binder_class = config[:binder]
          @proxy_class = config[:proxy]
          @eager_loader_class = config[:eager_loader]
        end

        def create_extension!(&block)
          return unless block

          extension_module_name = "#{owner_class.to_s.demodulize}#{name.to_s.camelize}RelationExtension"
          silence_warnings do
            owner_class.const_set(extension_module_name, Module.new(&block))
          end
          @extension = "#{owner_class}::#{extension_module_name}".constantize
        end

        def validate_options!
          @options.validate!(association_type, owner_class, name)

          [name, :"#{name}?", :"#{name}="].each do |n|
            next unless ActiveDocument.destructive_fields.include?(n)

            raise Errors::InvalidRelation.new(owner_class, n)
          end
        end

        def setup_index!
          index_spec = foreign_key_strategy.index_spec
          owner_class.index(index_spec) unless index_spec.empty?
        end

        def setup_polymorphic!
          return unless polymorphic?

          owner_class.polymorphic = true

          # For belongs_to_one, create the inverse_type field on this document
          owner_class.field(inverse_type, type: :string) if association_type == :belongs_to_one
        end

        def setup_callbacks!
          setup_autosave! if @options.autosave?
          setup_counter_cache! if counter_cached?
          setup_dependency! if dependent
          setup_touchable! if touchable?
          setup_syncing! if needs_syncing?
          setup_validation! if validate?
          setup_required! if require_association?
        end

        def setup_autosave!
          ActiveDocument::Association::Referenced::AutoSave.define_autosave!(self)
          @autosave_enabled = true
        end

        def setup_counter_cache!
          ActiveDocument::Association::Referenced::CounterCache.define_callbacks!(self)
        end

        def setup_dependency!
          ActiveDocument::Association::Depending.define_dependency!(self)
        end

        def setup_touchable!
          ActiveDocument::Touchable.define_touchable!(self)
        end

        def setup_syncing!
          # For belongs_to_many bidirectional sync
          synced_save
          synced_destroy
        end

        def needs_syncing?
          association_type == :belongs_to_many && !forced_nil_inverse?
        end

        def synced_save
          assoc = self
          owner_class.set_callback(
            :save,
            :after,
            if: ->(doc) { doc._syncable?(assoc) }
          ) do |doc|
            doc.update_inverse_keys(assoc)
          end
        end

        def synced_destroy
          assoc = self
          owner_class.set_callback(
            :destroy,
            :after
          ) do |doc|
            doc.remove_inverse_keys(assoc)
          end
        end

        def setup_validation!
          owner_class.validates_associated(name)
        end

        def setup_required!
          owner_class.validates(name, presence: true)
        end

        def require_association?
          return false unless association_type == :belongs_to_one

          required = @options[:required] if @options.key?(:required)
          required = !@options[:optional] if @options.key?(:optional) && required.nil?
          required.nil? ? ActiveDocument.belongs_to_required_by_default : required
        end

        def query?(object)
          return false if object.nil?
          return false if object.is_a?(Document)
          return false if object.is_a?(::Array)

          true
        end

        def execute_query(object, type = nil)
          cls = type ? resolve_type(type) : relation_class
          crit = cls.criteria
          crit = crit.apply_scope(scope) if scope
          crit.where(primary_key => object).first
        end

        def resolve_type(type)
          case type
          when String then type.constantize
          when Class then type
          else type
          end
        end

        def polymorphic_type(base)
          return nil unless polymorphic? && inverse_type

          type_value = base.send(inverse_type)
          resolver&.model_for(type_value) if type_value
        end

        def polymorphic_inverses(other)
          as_name = @options.as

          # For has_one/has_many with :as option
          if as_name
            # When no other object provided, return the :as option as the inverse name
            return [as_name] if other.nil?

            # Look for belongs_to :as_name, polymorphic: true on the related class
            # We look in relation_class.relations, not other.relations
            matches = relation_class.relations.values.select do |rel|
              next false unless valid_complement?(rel)

              rel.name.to_sym == as_name.to_sym && rel.polymorphic?
            end

            return matches.collect(&:name)
          end

          # For polymorphic belongs_to, look for has_one/has_many with as: matching our name
          return nil unless other

          matches = other.relations.values.select do |rel|
            next false unless valid_complement?(rel)

            # The inverse has_one/has_many should have :as matching our name
            # and its class should point to our owner class
            rel.as&.to_sym == name.to_sym &&
              rel.relation_class_name == inverse_class_name
          end

          matches.collect(&:name)
        end

        def determine_inverses(other)
          matches = (other || relation_class).relations.values.select do |rel|
            valid_complement?(rel) && rel.relation_class_name == inverse_class_name
          end

          if matches.size > 1
            raise Errors::AmbiguousRelationship.new(relation_class, owner_class, name, matches)
          end

          matches.collect(&:name)
        end

        def valid_complement?(rel)
          # Check if the relation's type is a valid complement
          return false unless rel.respond_to?(:association_type)

          relation_complements.include?(rel.association_type)
        rescue NoMethodError
          # For legacy associations without association_type
          false
        end

        def resolve_name(mod, cls_name)
          cls = exc = nil
          parts = cls_name.to_s.split('::')

          if parts.first == ''
            parts.shift
            hierarchy = [Object]
          else
            hierarchy = namespace_hierarchy(mod)
          end

          hierarchy.each do |ns|
            parts.each { |part| ns = ns.const_get(part, false) }
            cls = ns
            break
          rescue NameError => e
            exc = e if exc.nil?
          end

          raise exc if cls.nil?

          cls
        end

        def namespace_hierarchy(mod)
          parent = Object
          hier = [parent]

          mod.name&.split('::')&.each do |part|
            parent = parent.const_get(part)
            hier << parent
          end

          hier.reverse
        end

        def silence_warnings
          old_verbose = $VERBOSE
          $VERBOSE = nil
          yield
        ensure
          $VERBOSE = old_verbose
        end
      end
    end
  end
end
