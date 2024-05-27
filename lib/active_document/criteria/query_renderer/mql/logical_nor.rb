# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module QueryAST
      # The AST node for an logical "nor" ("none_of") operator.
      class LogicalNor < LogicalOperator
      end
    end
  end
end
