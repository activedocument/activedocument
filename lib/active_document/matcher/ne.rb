# frozen_string_literal: true

module ActiveDocument
  module Matcher

    # In-memory matcher for $ne expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/ne/
    #
    # @api private
    module Ne

      extend self

      # Returns whether a value satisfies an $ne expression.
      #
      # @param [ true | false ] exists Whether the value exists.
      # @param [ Object ] value The value to check.
      # @param [ Object ] condition The $ne condition predicate.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      def matches?(exists, value, condition)
        case condition
        when ::Regexp, BSON::Regexp::Raw
          raise Errors::InvalidQuery.new("'$ne' operator does not allow Regexp arguments: #{Errors::InvalidQuery.truncate_expr(condition)}")
        end

        !EqImpl.matches?(exists, value, condition, '$ne')
      end
    end
  end
end
