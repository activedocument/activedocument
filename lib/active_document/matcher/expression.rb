# frozen_string_literal: true

module ActiveDocument
  module Matcher

    # Base singleton module used for evaluating whether a given
    # document in-memory matches an MSQL query expression.
    #
    # @api private
    module Expression

      extend self

      # Returns whether a document satisfies a query expression.
      #
      # @param [ ActiveDocument::Document ] document The document.
      # @param [ Hash ] expr The expression.
      #
      # @return [ true | false ] Whether the document matches.
      #
      # @api private
      def matches?(document, expr)
        if expr.nil?
          raise Errors::InvalidQuery.new('Nil condition in expression context')
        end

        unless expr.is_a?(Hash)
          raise Errors::InvalidQuery.new('MQL query must be provided as a Hash')
        end

        expr.all? do |k, expr_v|
          k = k.to_s
          if k == '$comment'
            true
          elsif k.start_with?('$')
            ExpressionOperator.get(k).matches?(document, expr_v)
          else
            values = Matcher.extract_attribute(document, k)
            if values.empty?
              FieldExpression.matches?(false, nil, expr_v)
            else
              values.any? do |v|
                FieldExpression.matches?(true, v, expr_v)
              end
            end
          end
        end
      end
    end
  end
end
