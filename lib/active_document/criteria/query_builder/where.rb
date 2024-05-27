# frozen_string_literal: true

module ActiveDocument
  module Matcher

    # Singleton module provides lookup of query operator matchers
    # related to field values.
    #
    # @api private
    module Where
      extend self

      # Check this: https://www.mongodb.com/docs/manual/reference/operator/query/
      MAP = {
        '$all' => All,
        '$bitsAllClear' => FieldBitsAllClear,
        '$bitsAllSet' => FieldBitsAllSet,
        '$bitsAnyClear' => FieldBitsAnyClear,
        '$bitsAnySet' => FieldBitsAnySet,
        '$elemMatch' => FieldElemMatch, # ArrayMatch, ContainsMatch
        '$eq' => FieldEquals,
        '$exists' => FieldExists,
        '$gt' => FieldGt,
        '$gte' => FieldGte,
        '$in' => FieldAnyIn,
        '$lt' => FieldLt,
        '$lte' => FieldLte,
        '$mod' => FieldMod,
        '$nin' => FieldNotIn,
        '$ne' => FieldNotEquals,
        '$not' => LogicalNot,
        '$regex' => FieldRegex,
        '$size' => FieldArraySize,
        '$type' => FieldType,
        '$type' => FieldType,
      }.freeze

      # Returns the matcher module for a given operator.
      #
      # @param [ String ] operator The operator name.
      #
      # @return [ Module ] The matcher module.
      #
      # @raises [ ActiveDocument::Errors::InvalidFieldOperator ]
      #   Raised if the given operator is unknown.
      #
      # @api private
      def get(operator)
        MAP.fetch(operator)
      rescue KeyError
        raise Errors::InvalidFieldOperator.new(operator)
      end

      # Used for evaluating $lt, $lte, $gt, $gte comparison operators.
      #
      # @todo Refactor this as it is only relevant to $lt, $lte, $gt, $gte.
      #
      # @api private
      def apply_array_field_operator(_exists, value, _condition, &block)
        if value.is_a?(Array)
          value.any?(&block)
        else
          yield value
        end
      end

      # Used for evaluating $lt, $lte, $gt, $gte comparison operators.
      #
      # @todo Refactor this as it is only relevant to $lt, $lte, $gt, $gte.
      #
      # @api private
      def apply_comparison_operator(operator, left, right)
        left.send(operator, right)
      rescue ArgumentError, NoMethodError, TypeError
        # We silence bogus comparison attempts, e.g. number to string
        # comparisons.
        # Several different exceptions may be produced depending on the types
        # involved.
        false
      end
    end
  end
end
