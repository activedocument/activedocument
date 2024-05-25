# frozen_string_literal: true

module ActiveDocument

  # This module contains behavior for all ActiveDocument scoping - named scopes,
  # default scopes, and criteria accessors via scoped and unscoped.
  module Scopable
    extend ActiveSupport::Concern

    included do
      class_attribute :default_scoping
      class_attribute :_declared_scopes
      self._declared_scopes = {}
    end

    private

    # Apply the default scoping to the attributes of the document, as long as
    # they are not complex queries.
    #
    # @api private
    #
    # @example Apply the default scoping.
    #   document.apply_default_scoping
    #
    # @return [ true | false ] If default scoping was applied.
    def apply_default_scoping
      return unless default_scoping

      default_scoping.call.selector.each do |field, value|
        attributes[field] = value unless value.respond_to?(:each)
      end
    end

    module ClassMethods

      # Returns a hash of all the scopes defined for this class, including
      # scopes defined on ancestor classes.
      #
      # @example Get the defined scopes for a class
      #   class Band
      #     include ActiveDocument::Document
      #     field :active, type: :boolean
      #
      #     scope :active, -> { where(active: true) }
      #   end
      #   Band.scopes
      #
      # @return [ Hash ] The scopes defined for this class
      def scopes
        defined_scopes = {}

        ancestors.reverse_each do |klass|
          next unless klass.respond_to?(:_declared_scopes)

          defined_scopes.merge!(klass._declared_scopes)
        end

        defined_scopes.freeze
      end

      # Add a default scope to the model. This scope will be applied to all
      # criteria unless #unscoped is specified.
      #
      # @example Define a default scope with a criteria.
      #   class Band
      #     include ActiveDocument::Document
      #     field :active, type: :boolean
      #     default_scope where(active: true)
      #   end
      #
      # @example Define a default scope with a proc.
      #   class Band
      #     include ActiveDocument::Document
      #     field :active, type: :boolean
      #     default_scope ->{ where(active: true) }
      #   end
      #
      # @param [ Proc | ActiveDocument::Criteria ] value The default scope.
      #
      # @raise [ Errors::InvalidScope ] If the scope is not a proc or criteria.
      #
      # @return [ Proc ] The default scope.
      def default_scope(value = nil, &block)
        value = proc(&block) if block
        check_scope_validity(value)
        self.default_scoping = process_default_scope(value)
      end

      # Is the class able to have the default scope applied?
      #
      # @example Can the default scope be applied?
      #   Band.default_scopable?
      #
      # @return [ true | false ] If the default scope can be applied.
      def default_scopable?
        default_scoping? && !Threaded.without_default_scope?(self)
      end

      # Get a queryable, either the last one on the scope stack or a fresh one.
      #
      # @api private
      #
      # @example Get a queryable.
      #   Model.queryable
      #
      # @return [ ActiveDocument::Criteria ] The queryable.
      def queryable
        crit = Threaded.current_scope(self) || Criteria.new(self)
        crit.embedded = true if crit.klass.embedded? && !crit.klass.cyclic?
        crit
      end

      # Create a scope that can be accessed from the class level or chained to
      # criteria by the provided name.
      #
      # @example Create named scopes.
      #
      #   class Person
      #     include ActiveDocument::Document
      #     field :active, type: :boolean
      #     field :count, type: :integer
      #
      #     scope :active, -> { where(active: true) }
      #     scope :at_least, ->(count){ where(:count.gt => count) }
      #   end
      #
      # @param [ Symbol ] name The name of the scope.
      # @param [ Proc ] value The conditions of the scope.
      #
      # @raise [ Errors::InvalidScope ] If the scope is not a proc.
      # @raise [ Errors::ScopeOverwrite ] If the scope name already exists.
      def scope(name, value, &block)
        normalized = name.to_sym
        check_scope_validity(value)
        check_scope_name(normalized)
        _declared_scopes[normalized] = {
          scope: value,
          extension: Module.new(&block)
        }
        define_scope_method(normalized)
      end

      # Get a criteria for the document with normal scoping.
      #
      # @example Get the criteria.
      #   Band.scoped(skip: 10)
      #
      # @note This will force the default scope to be applied.
      #
      # @param [ Hash ] options Query options for the criteria.
      #
      # @option options [ Integer ] :skip Optional number of documents to skip.
      # @option options [ Integer ] :limit Optional number of documents to
      #   limit.
      # @option options [ Array ] :sort Optional sorting options.
      #
      # @return [ ActiveDocument::Criteria ] A scoped criteria.
      def scoped(options = nil)
        queryable.scoped(options)
      end

      # Get the criteria without any scoping applied.
      #
      # @example Get the unscoped criteria.
      #   Band.unscoped
      #
      # @example Yield to block with no scoping.
      #   Band.unscoped do
      #     Band.where(name: "Depeche Mode")
      #   end
      #
      # @note This will force the default scope, as well as any scope applied
      #   using ``.with_scope``, to be removed.
      #
      # @return [ ActiveDocument::Criteria | Object ] The unscoped criteria or result of the
      #   block.
      def unscoped
        if block_given?
          without_default_scope do
            with_scope(nil) do
              yield(self)
            end
          end
        else
          queryable.unscoped
        end
      end

      # Get a criteria with the default scope applied, if possible.
      #
      # @example Get a criteria with the default scope.
      #   Model.with_default_scope
      #
      # @return [ ActiveDocument::Criteria ] The criteria.
      def with_default_scope
        queryable.with_default_scope
      end
      alias_method :criteria, :with_default_scope

      # Pushes the provided criteria onto the scope stack, and removes it after the
      # provided block is yielded.
      #
      # @example Yield to the criteria.
      #   Person.with_scope(criteria)
      #
      # @param [ ActiveDocument::Criteria ] criteria The criteria to apply.
      #
      # @return [ ActiveDocument::Criteria ] The yielded criteria.
      def with_scope(criteria)
        previous = Threaded.current_scope(self)
        Threaded.set_current_scope(criteria, self)
        begin
          yield criteria
        ensure
          Threaded.set_current_scope(previous, self)
        end
      end

      # Execute the block without applying the default scope.
      #
      # @example Execute without the default scope.
      #   Band.without_default_scope do
      #     Band.where(name: "Depeche Mode")
      #   end
      #
      # @return [ Object ] The result of the block.
      def without_default_scope
        Threaded.begin_without_default_scope(self)
        yield
      ensure
        Threaded.exit_without_default_scope(self)
      end

      private

      # Warns or raises exception if overriding another scope or method.
      #
      # @api private
      #
      # @example Warn or raise error if name exists.
      #   Model.check_scope_name("test")
      #
      # @param [ String | Symbol ] name The name of the scope.
      #
      # @raise [ Errors::ScopeOverwrite ] If the name exists and configured to
      #   raise the error.
      def check_scope_name(name)
        return unless _declared_scopes[name] || respond_to?(name, true)

        raise Errors::ScopeOverwrite.new(self.name, name) if ActiveDocument.scope_overwrite_exception

        ActiveDocument.logger.warn(
          "Creating scope :#{name} which conflicts with #{self.name}.#{name}. " \
          "Calls to `ActiveDocument::Criteria##{name}` will delegate to " \
          "`ActiveDocument::Criteria##{name}` for criteria with klass #{self.name} " \
          'and will ignore the declared scope.'
        )
      end

      # Checks if the intended scope is a valid object, either a criteria or
      # proc with a criteria.
      #
      # @api private
      #
      # @example Check if the scope is valid.
      #   Model.check_scope_validity({})
      #
      # @param [ Object ] value The intended scope.
      #
      # @raise [ Errors::InvalidScope ] If the scope is not a valid object.
      def check_scope_validity(value)
        return if value.respond_to?(:call)

        raise Errors::InvalidScope.new(self, value)
      end

      # Defines the actual class method that will execute the scope when
      # called.
      #
      # @api private
      #
      # @example Define the scope class method.
      #   Model.define_scope_method(:active)
      #
      # @param [ Symbol ] name The method/scope name.
      #
      # @return [ Method ] The defined method.
      def define_scope_method(name)
        singleton_class.class_eval do
          define_method(name) do |*args, **kwargs|
            scoping = _declared_scopes[name]
            scope = instance_exec(*args, **kwargs, &scoping[:scope])
            extension = scoping[:extension]
            to_merge = scope || queryable
            criteria = to_merge.empty_and_chainable? ? to_merge : with_default_scope.merge(to_merge)
            criteria.extend(extension)
            criteria
          end
        end
      end

      # Process the default scope value. If one already exists, we merge the
      # new one into the old one.
      #
      # @api private
      #
      # @example Process the default scope.
      #   Model.process_default_scope(value)
      #
      # @param [ ActiveDocument::Criteria | Proc ] value The default scope value.
      def process_default_scope(value)
        if (existing = default_scoping)
          -> { existing.call.merge(value.to_proc.call) }
        else
          value.to_proc
        end
      end
    end
  end
end