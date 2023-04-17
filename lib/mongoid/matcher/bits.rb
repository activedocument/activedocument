# frozen_string_literal: true

module Mongoid
  module Matcher

    # Mixin module included in bitwise expression matchers.
    #
    # @api private
    module Bits

      extend self

      # Returns whether a value satisfies a bitwise expression.
      #
      # @param [ true | false ] exists Not used.
      # @param [ Object ] value The value to check.
      # @param [ Numeric | Array<Numeric> ] condition The expression
      #   predicate as a bitmask or position list.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      def matches?(exists, value, condition)
        case value
        when BSON::Binary
          value = value.data.chars.map { |n| '%02x' % n.ord }.join.to_i(16)
        end
        case condition
        when Array
          array_matches?(value, condition)
        when BSON::Binary
          int_cond = condition.data.chars.map { |n| '%02x' % n.ord }.join.to_i(16)
          int_matches?(value, int_cond)
        when Integer
          if condition < 0
            raise Errors::InvalidQuery.new("Invalid value for $#{operator_name} argument: negative integers are not allowed: #{condition}")
          end

          int_matches?(value, condition)
        when Float
          int_cond = condition.to_i
          unless (condition - int_cond.to_f).abs < Float::EPSILON
            raise Errors::InvalidQuery.new("Invalid type for $#{operator_name} argument: not representable as an integer: #{condition}")
          end

          if int_cond < 0
            raise Errors::InvalidQuery.new("Invalid value for $#{operator_name} argument: negative numbers are not allowed: #{condition}")
          end

          int_matches?(value, int_cond)
        else
          raise Errors::InvalidQuery.new("Invalid type for $#{operator_name} argument: #{condition}")
        end
      end

      # Returns the name of the expression operator.
      #
      # @return [ String ] The operator name.
      #
      # @api private
      def operator_name
        name.sub(/.*::/, '').sub(/\A(.)/, &:downcase)
      end
    end
  end
end
