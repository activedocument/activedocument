# frozen_string_literal: true

module Mongoid
  module Matcher

    # In-memory matcher for $lte expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/lte/
    #
    # @api private
    module Lte

      extend self

      # Returns whether a value satisfies a $lte expression.
      #
      # @param [ true | false ] exists Whether the value exists.
      # @param [ Object ] value The value to check.
      # @param [ Object ] condition The $lte condition predicate.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      def matches?(exists, value, condition)
        case condition
        when Range
          raise Errors::InvalidQuery.new("$lte argument cannot be a Range: #{Errors::InvalidQuery.truncate_expr(condition)}")
        end
        FieldOperator.apply_array_field_operator(exists, value, condition) do |v|
          FieldOperator.apply_comparison_operator(:<=, v, condition)
        end
      end
    end
  end
end
