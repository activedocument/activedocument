# frozen_string_literal: true

module Dynamoid
  # The base association module which all associations include. Every association has two very important components: the source and
  # the target. The source is the object which is calling the association information. It always has the target_ids inside of an attribute on itself.
  # The target is the object which is referencing by this association.
  # @private
  module Associations
    # @private
    module Association
      attr_accessor :name, :options, :source, :loaded

      # Create a new association.
      #
      # @param [Class] source the source record of the association; that is, the record that you already have
      # @param [Symbol] name the name of the association
      # @param [Hash] options optional parameters for the association
      # @option options [Class] :class the target class of the association; that is, the class to which the association objects belong
      # @option options [Symbol] :class_name the name of the target class of the association; only this or Class is necessary
      # @option options [Symbol] :inverse_of the name of the association on the target class
      # @option options [Symbol] :foreign_key the name of the field for belongs_to association
      #
      # @return [Dynamoid::Association] the actual association instance itself
      #
      # @since 0.2.0
      def initialize(source, name, options)
        @name = name
        @options = options
        @source = source
        @loaded = false
      end

      def loaded?
        @loaded
      end

      def find_target; end

      def target
        unless loaded?
          @target = find_target
          @loaded = true
        end

        @target
      end

      def reset
        @target = nil
        @loaded = false
      end

      def declaration_field_name
        "#{name}_ids"
      end

      def declaration_field_type
        :set
      end

      def disassociate_source
        Array(target).each do |target_entry|
          target_entry.send(target_association).disassociate(source.hash_key) if target_entry && target_association
        end
      end

      private

      # The target class name, either inferred through the association's name or specified in options.
      #
      # @since 0.2.0
      def target_class_name
        options[:class_name] || name.to_s.classify
      end

      # The target class, either inferred through the association's name or specified in options.
      #
      # @since 0.2.0
      def target_class
        options[:class] || target_class_name.constantize
      end

      # The target attribute: that is, the attribute on each object of the association that should reference the source.
      #
      # @since 0.2.0
      def target_attribute
        # In simple case it's equivalent to
        # "#{target_association}_ids".to_sym if target_association
        if target_association
          target_options = target_class.associations[target_association]
          assoc = Dynamoid::Associations.const_get(target_options[:type].to_s.camelcase).new(nil, target_association, target_options)
          assoc.send(:source_attribute)
        end
      end

      # The ids in the target association.
      #
      # @since 0.2.0
      def target_ids
        target.send(target_attribute) || Set.new
      end

      # The ids in the target association.
      #
      # @since 0.2.0
      def source_class
        source.class
      end

      # The source's association attribute: the name of the association with _ids afterwards, like "users_ids".
      #
      # @since 0.2.0
      def source_attribute
        declaration_field_name.to_sym
      end

      # The ids in the source association.
      #
      # @since 0.2.0
      def source_ids
        # handle case when we store scalar value instead of collection (when foreign_key option is specified)
        Array(source.send(source_attribute)).compact.to_set || Set.new
      end

      # Create a new instance of the target class without trying to add it to the association. This creates a base, that caller can update before setting or adding it.
      #
      # @param attributes [Hash] attribute values for the new object
      #
      # @return [Dynamoid::Document] the newly-created object
      #
      # @since 1.1.1
      def build(attributes = {})
        target_class.build(attributes)
      end
    end
  end
end
