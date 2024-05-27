# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module QueryAST
      # The root node of the AST tree.
      class RootNode < LogicalAnd
      end
    end
  end
end
