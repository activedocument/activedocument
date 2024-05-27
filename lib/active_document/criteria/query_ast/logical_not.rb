# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module QueryAST
      # The AST node for the negation operator.
      class LogicalNot < LogicalOperator
      end
    end
  end
end
