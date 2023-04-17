# frozen_string_literal: true

module Mongoid
  module Matcher

    # In-memory matcher for $size expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/size/
    #
    # @api private
    module Size

      extend self

      # Returns whether a value satisfies a $size expression.
      #
      # @param [ true | false ] exists Not used.
      # @param [ Numeric ] value The value to check.
      # @param [ Integer | Array<Object> ] condition The $size condition
      #   predicate, either a non-negative Integer or an Array to match size.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      def matches?(exists, value, condition)
        unless condition.is_a?(Numeric) && !condition.is_a?(Float) && condition >= 0
          raise Errors::InvalidQuery.new("$size argument must be a non-negative integer: #{Errors::InvalidQuery.truncate_expr(condition)}")
        end

        return false unless value.is_a?(Array)

        value.length == condition
      end
    end
  end
end
