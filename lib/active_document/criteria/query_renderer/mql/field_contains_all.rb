# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module QueryAST
      # The AST node for an array field "contains all" condition.
      class FieldContainsAll < FieldOperator
      end
    end
  end
end
