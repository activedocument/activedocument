# frozen_string_literal: true

module ActiveDocument
  module Matcher

    # This module is used by $eq and other operators that need to perform
    # the matching that $eq performs (for example, $ne which negates the result
    # of $eq). Unlike $eq this module takes an original operator as an
    # additional argument to +matches?+ to provide the correct exception
    # messages reflecting the operator that was first invoked.
    #
    # @api private
    module EqImpl

      extend self

      # Returns whether a value satisfies an $eq (or similar) expression.
      #
      # @param [ true | false ] _exists Not used.
      # @param [ Object ] value The value to check.
      # @param [ Object | Range ] condition The equality condition predicate.
      # @param [ String ] _original_operator Operator to use in exception messages. Not used.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      def matches?(_exists, value, condition, _original_operator)
        case condition
        when Range
          if value.is_a?(Array)
            value.any? { |v| condition.include?(v) }
          else
            condition.include?(value)
          end
        else
          # When doing a comparison with Time objects, compare using millisecond precision
          if value.is_a?(Time) && condition.is_a?(Time)
            time_eq?(value, condition)
          elsif value.is_a?(Array) && condition.is_a?(Time)
            value.map do |v|
              if v.is_a?(Time)
                time_rounded_to_millis(v)
              else
                v
              end
            end.include?(time_rounded_to_millis(condition))
          else
            value == condition ||
              (value.is_a?(Array) && value.include?(condition))
          end
        end
      end

      # Per https://www.mongodb.com/docs/ruby-driver/current/tutorials/bson-v4/#time-instances,
      # > Times in BSON (and MongoDB) can only have millisecond precision. When Ruby Time instances
      # are serialized to BSON or Extended JSON, the times are floored to the nearest millisecond.
      #
      # > Because of this flooring, applications are strongly recommended to perform all time
      # calculations using integer math, as inexactness of floating point calculations may produce
      # unexpected results.
      #
      # As such, perform a similar operation to what the bson-ruby gem does.
      #
      # @param [ Time ] time_a The first time value.
      # @param [ Time ] time_b The second time value.
      #
      # @return [ true | false ] Whether the two times are equal to the millisecond.
      #
      # @api private
      def time_eq?(time_a, time_b)
        time_rounded_to_millis(time_a) == time_rounded_to_millis(time_b)
      end

      private

      # Rounds a time value to nearest millisecond.
      #
      # @param [ Time ] time The time value.
      #
      # @return [ true | false ] The time rounded to the millisecond.
      #
      # @api private
      def time_rounded_to_millis(time)
        (time._bson_to_i * 1000) + time.usec.divmod(1000).first
      end
    end
  end
end
