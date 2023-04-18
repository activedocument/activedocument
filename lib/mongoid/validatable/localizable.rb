# frozen_string_literal: true

module Mongoid
  module Validatable

    # Adds localization support to validations.
    module Localizable

      # Validates each for localized fields.
      #
      # @example Validate localized fields.
      #   validator.validate_each(model, :name, "value")
      #
      # @param [ Mongoid::Document ] document The document.
      # @param [ Symbol | String ] attribute The attribute to validate.
      # @param [ Object ] value The attribute value.
      def validate_each(document, attribute, value)
        field = document.fields[document.database_field_name(attribute)]
        if field.try(:localized?) && !value.blank?
          value.each_value do |val|
            super(document, attribute, val)
          end
        else
          super
        end
      end
    end
  end
end
