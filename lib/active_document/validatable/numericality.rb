# frozen_string_literal: true

module ActiveDocument
  module Validatable
    # A specialization of the ActiveModel numericality validator, which adds
    # logic to recognize and accept BSON::Decimal128 as a number.
    class NumericalityValidator < ActiveModel::Validations::NumericalityValidator
      private

      # Ensure that BSON::Decimal128 is treated as a BigDecimal during the
      # validation step.
      def prepare_value_for_validation(value, record, attr_name)
        result = super

        result.is_a?(BSON::Decimal128) ? result.to_big_decimal : result
      end
    end
  end
end
