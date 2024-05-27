# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module QueryAST
      # The AST node for an logical "and" ("all_of") operator.
      class LogicalAnd < LogicalOperator
      end
    end
  end
end
