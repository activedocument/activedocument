# frozen_string_literal: true

module ActiveDocument
  module Matcher

    # This is an internal equality implementation that performs exact
    # comparisons and regular expression matches.
    #
    # @api private
    module EqImplWithRegexp

      extend self

      # Returns whether a value satisfies an $eq (or similar) expression,
      # performing a regular expression match if the condition is a regular
      # expression.
      #
      # @param [ String ] _original_operator Not used.
      # @param [ Object ] value The value to check.
      # @param [ Object ] condition The equality condition predicate.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      def matches?(_original_operator, value, condition)
        case condition
        when Regexp
          value =~ condition
        when ::BSON::Regexp::Raw
          value =~ condition.compile
        else
          if value.is_a?(Time) && condition.is_a?(Time)
            EqImpl.time_eq?(value, condition)
          else
            value == condition
          end
        end
      end
    end
  end
end
