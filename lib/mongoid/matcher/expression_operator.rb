# frozen_string_literal: true

module Mongoid
  module Matcher

    # Singleton module provides lookup of logical query operator
    # matchers.
    #
    # @api private
    module ExpressionOperator
      MAP = {
        '$and' => And,
        '$nor' => Nor,
        '$or' => Or
      }.freeze

      extend self

      # Returns the matcher module for a given operator.
      #
      # @param [ String ] operator The operator name.
      #
      # @return [ Module ] The matcher module.
      #
      # @raises [ Mongoid::Errors::InvalidExpressionOperator ]
      #   Raised if the given operator is unknown.
      #
      # @api private
      def get(operator)
        MAP.fetch(operator)
      rescue KeyError
        raise Errors::InvalidExpressionOperator.new(operator)
      end
    end
  end
end
