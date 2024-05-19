# frozen_string_literal: true

module ActiveDocument
  module Matcher

    # In-memory matcher for $in expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/in/
    #
    # @api private
    module In

      extend self

      # Returns whether a value satisfies an $in expression.
      #
      # @param [ true | false ] _exists Not used.
      # @param [ Object ] value The value to check.
      # @param [ Array<Object> ] condition The $in condition predicate.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      def matches?(_exists, value, condition)
        unless condition.is_a?(Array)
          raise Errors::InvalidQuery.new("$in argument must be an array: #{Errors::InvalidQuery.truncate_expr(condition)}")
        end

        if value.is_a?(Array) &&
           value.any? { |v| condition.any? { |c| EqImplWithRegexp.matches?('$in', v, c) } }
          return true
        end

        condition.any? { |c| EqImplWithRegexp.matches?('$in', value, c) }
      end
    end
  end
end
