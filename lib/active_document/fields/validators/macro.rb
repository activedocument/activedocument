# frozen_string_literal: true

module ActiveDocument
  module Fields
    module Validators

      # Validates the params passed to the field macro.
      module Macro
        extend self

        OPTIONS = %i[
          as
          default
          identity
          label
          localize
          fallbacks
          association
          pre_processed
          subtype
          type
          overwrite
          encrypt
        ].freeze

        # Validate the field definition.
        #
        # @example Validate the field definition.
        #   Macro.validate(Model, :name, { localized: true })
        #
        # @param [ Class ] klass The model class.
        # @param [ Symbol ] name The field name.
        # @param [ Hash ] options The provided options.
        def validate(klass, name, options)
          validate_field_name(klass, name)
          validate_name_uniqueness(klass, name, options)
          validate_options(klass, name, options)
        end

        # Validate the association definition.
        #
        # @example Validate the association definition.
        #   Macro.validate(Model, :name)
        #
        # @param [ Class ] klass The model class.
        # @param [ Symbol ] name The field name.
        # @param [ Hash ] _options The provided options.
        def validate_relation(klass, name, _options = {})
          [name, :"#{name}?", :"#{name}="].each do |n|
            if ActiveDocument.destructive_fields.include?(n)
              raise Errors::InvalidRelation.new(klass, n)
            end
          end
        end

        # Determine if the field name is valid, if not raise an error.
        #
        # @example Check the field name.
        #   Macro.validate_field_name(Model, :name)
        #
        # @param [ Class ] klass The model class.
        # @param [ Symbol ] name The field name.
        #
        # @raise [ Errors::InvalidField ] If the name is not allowed.
        #
        # @api private
        def validate_field_name(klass, name)
          [name, :"#{name}?", :"#{name}="].each do |n|
            if ActiveDocument.destructive_fields.include?(n)
              raise Errors::InvalidField.new(klass, name, n)
            end
          end
        end

        private

        # Determine if the field name is unique, if not raise an error.
        #
        # @example Check the field name.
        #   Macro.validate_name_uniqueness(Model, :name, {})
        #
        # @param [ Class ] klass The model class.
        # @param [ Symbol ] name The field name.
        # @param [ Hash ] options The provided options.
        #
        # @raise [ Errors::InvalidField ] If the name is not allowed.
        #
        # @api private
        def validate_name_uniqueness(klass, name, options)
          return unless !options[:overwrite] && klass.fields.key?(name.to_s)

          raise Errors::InvalidField.new(klass, name, name) if ActiveDocument.duplicate_fields_exception

          ActiveDocument.logger&.warn("Overwriting existing field #{name} in class #{klass.name}.")
        end

        # Validate that the field options are allowed.
        #
        # @api private
        #
        # @example Validate the field options.
        #   Macro.validate_options(Model, :name, { localized: true })
        #
        # @param [ Class ] klass The model class.
        # @param [ Symbol ] name The field name.
        # @param [ Hash ] options The provided options.
        #
        # @raise [ Errors::InvalidFieldOption ] If an option is invalid.
        def validate_options(klass, name, options)
          options.each_key do |option|
            unless OPTIONS.include?(option) || Fields.options.include?(option)
              raise Errors::InvalidFieldOption.new(klass, name, option, OPTIONS)
            end
          end
        end
      end
    end
  end
end
