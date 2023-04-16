# frozen_string_literal: true

module Mongoid
  module Matcher

    # In-memory matcher for $or expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/or/
    #
    # @api private
    module Or

      extend self

      # Returns whether a document satisfies an $or expression.
      #
      # @param [ Mongoid::Document ] document The document.
      # @param [ Array<Hash> ] expr The $or conditions.
      #
      # @return [ true | false ] Whether the document matches.
      #
      # @api private
      def matches?(document, expr)
        unless expr.is_a?(Array)
          raise Errors::InvalidQuery.new("$or argument must be an array: #{Errors::InvalidQuery.truncate_expr(expr)}")
        end

        if expr.empty?
          raise Errors::InvalidQuery.new("$or argument must be a non-empty array: #{Errors::InvalidQuery.truncate_expr(expr)}")
        end

        expr.any? do |sub_expr|
          Expression.matches?(document, sub_expr)
        end
      end
    end
  end
end
