# frozen_string_literal: true

module Mongoid
  module Matcher

    # In-memory matcher for $exists expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/exists/
    #
    # @api private
    module Exists

      extend self

      # Returns whether an $exists expression is satisfied.
      #
      # @param [ true | false ] exists Whether the value exists.
      # @param [ Object ] _value Not used.
      # @param [ true | false ] condition The $exists condition predicate.
      #
      # @return [ true | false ] Whether the existence condition is met.
      #
      # @api private
      def matches?(exists, _value, condition)
        case condition
        when Range
          raise Errors::InvalidQuery.new("$exists argument cannot be a Range: #{Errors::InvalidQuery.truncate_expr(condition)}")
        end
        exists == (condition || false)
      end
    end
  end
end
