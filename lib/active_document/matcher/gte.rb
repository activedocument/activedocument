# frozen_string_literal: true

module ActiveDocument
  module Matcher

    # In-memory matcher for $gte expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/gte/
    #
    # @api private
    module Gte

      extend self

      # Returns whether a value satisfies a $gte expression.
      #
      # @param [ true | false ] exists Whether the value exists.
      # @param [ Object ] value The value to check.
      # @param [ Object ] condition The $gte condition predicate.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      def matches?(exists, value, condition)
        case condition
        when Range
          raise Errors::InvalidQuery.new("$gte argument cannot be a Range: #{Errors::InvalidQuery.truncate_expr(condition)}")
        end
        FieldOperator.apply_array_field_operator(exists, value, condition) do |v|
          FieldOperator.apply_comparison_operator(:>=, v, condition)
        end
      end
    end
  end
end
