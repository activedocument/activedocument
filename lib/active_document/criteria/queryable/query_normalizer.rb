# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module Queryable

      # Singleton module for normalizing query expressions.
      module QueryNormalizer
        extend self

        # Takes a criteria hash and expands Key objects into hashes containing
        # MQL corresponding to said key objects. Also converts the input to
        # BSON::Document to permit indifferent access.
        #
        # The argument must be a hash containing key-value pairs of the
        # following forms:
        # - { field_name: value }
        # - { 'field_name' => value }
        # - { :$operator => operator_value_expression }
        # - { '$operator' => operator_value_expression }
        #
        # This method effectively converts symbol keys to string keys in
        # the input +expr+, such that the downstream code can assume that
        # conditions always contain string keys.
        #
        # @param [ Hash ] expr Query expression including nested hashes.
        #
        # @return [ BSON::Document ] The expanded criteria.
        #
        # @api private
        def normalize_expr(expr, negating: false)
          unless expr.is_a?(Hash)
            raise ArgumentError.new('Argument must be a Hash')
          end

          expr = expr.transform_values do |value|
            if negating
              { value.is_a?(Hash) || regexp?(value) ? '$not' : '$ne' => value }
            else
              value
            end
          end

          BSON::Document.new(expr)
        end

        # Expand criterion values to arrays, to be used with operators that
        # take an array as argument such as $in.
        #
        # @example Convert all the values to arrays.
        #   selectable.with_array_values({ key: 1...4 })
        #
        # @param [ Hash ] criterion The criterion.
        #
        # @return [ Hash ] The $in friendly criterion with array values.
        #
        # @api private
        # TODO: remove this, properly support ranges on any_in, etc., raise error for scalars
        def expand_condition_to_array_values(criterion)
          raise ArgumentError.new('Criterion cannot be nil here') if criterion.nil?

          criterion.transform_values { |value| to_array(value) }
        end

        private

        # Returns whether the object is Regexp-like.
        #
        # @param [ Object ] object The object to evaluate.
        #
        # @return [ Boolean ] Whether the object is Regexp-like.
        def regexp?(object)
          object.is_a?(Regexp) || object.is_a?(BSON::Regexp::Raw)
        end

        # Get the object as an array or wrapped by an array.
        #
        # @example Get the range as an array.
        #   QueryNormalizer.to_array(1...3)
        #
        # @return [ Array ] The object as an array.
        def to_array(object)
          case object
          when Array
            object
          when Range
            object.to_a
          else
            [object]
          end
        end
      end
    end
  end
end
