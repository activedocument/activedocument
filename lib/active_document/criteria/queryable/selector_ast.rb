# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module Queryable

      # This selector holds AST representation of a query
      class SelectorAST
        attr_reader :tree

        def initialize(mql_hash)
          @tree = ActiveDocument::Parser::MQL.parse(mql_hash)
        end

        def ==(other)
          tree == other.tree
        end

        def inspect
          return '()' unless tree

          tree.inspect
        end

      end
    end
  end
end
