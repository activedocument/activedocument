# frozen_string_literal: true

module ActiveDocument
  module Matcher

    # Singleton module provides lookup of query operator matchers
    # related to field values.
    #
    # @api private
    module FieldOperator

      extend self

      MAP = {
        '$all' => All,
        '$bitsAllClear' => BitsAllClear,
        '$bitsAllSet' => BitsAllSet,
        '$bitsAnyClear' => BitsAnyClear,
        '$bitsAnySet' => BitsAnySet,
        '$elemMatch' => ElemMatch,
        '$eq' => Eq,
        '$exists' => Exists,
        '$gt' => Gt,
        '$gte' => Gte,
        '$in' => In,
        '$lt' => Lt,
        '$lte' => Lte,
        '$mod' => Mod,
        '$nin' => Nin,
        '$ne' => Ne,
        '$not' => Not,
        '$regex' => Regex,
        '$size' => Size,
        '$type' => Type
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
