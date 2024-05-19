# frozen_string_literal: true

module ActiveDocument
  module Errors

    # Raised when invalid query is passed to an embedded matcher, or an
    # invalid query fragment is passed to the query builder (Criteria object).
    class InvalidQuery < ActiveDocumentError

      # Stringifies the argument using #inspect and truncates the result to
      # about 100 characters.
      #
      # @param [ Object ] expr An expression to stringify and truncate.
      #
      # @api private
      def self.truncate_expr(expr)
        expr = expr.inspect unless expr.is_a?(String)

        if expr.length > 103
          expr = if /\A<#((?:.|\n)*)>\z/.match?(expr)
                   "<##{expr.slice(0, 97)}...>"
                 else
                   "#{expr.slice(0, 100)}..."
                 end
        end

        expr
      end
    end
  end
end
