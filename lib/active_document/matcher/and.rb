# frozen_string_literal: true

module ActiveDocument
  module Matcher

    # In-memory matcher for $and expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/and/
    #
    # @api private
    module And

      extend self

      # Returns whether a document satisfies an $and expression.
      #
      # @param [ ActiveDocument::Document ] document The document.
      # @param [ Array<Hash> ] expr The $and conditions.
      #
      # @return [ true | false ] Whether the document matches.
      #
      # @api private
      def matches?(document, expr)
        unless expr.is_a?(Array)
          raise Errors::InvalidQuery.new("$and argument must be an array: #{Errors::InvalidQuery.truncate_expr(expr)}")
        end

        if expr.empty?
          raise Errors::InvalidQuery.new("$and argument must be a non-empty array: #{Errors::InvalidQuery.truncate_expr(expr)}")
        end

        expr.all? do |sub_expr|
          Expression.matches?(document, sub_expr)
        end
      end
    end
  end
end
