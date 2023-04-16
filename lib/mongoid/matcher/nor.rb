# frozen_string_literal: true

module Mongoid
  module Matcher

    # In-memory matcher for $nor expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/nor/
    #
    # @api private
    module Nor

      extend self

      # Returns whether a document satisfies a $nor expression.
      #
      # @param [ Mongoid::Document ] document The document.
      # @param [ Array<Hash> ] expr The $nor conditions.
      #
      # @return [ true | false ] Whether the document matches.
      #
      # @api private
      def matches?(document, expr)
        unless expr.is_a?(Array)
          raise Errors::InvalidQuery.new("$nor argument must be an array: #{Errors::InvalidQuery.truncate_expr(expr)}")
        end

        if expr.empty?
          raise Errors::InvalidQuery.new("$nor argument must be a non-empty array: #{Errors::InvalidQuery.truncate_expr(expr)}")
        end

        expr.each do |sub_expr|
          return false if Expression.matches?(document, sub_expr)
        end

        expr.any?
      end
    end
  end
end
