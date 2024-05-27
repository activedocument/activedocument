# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module QueryAST
      # The AST node for a field "equals" condition.
      class FieldEquals < FieldOperator
      end
    end
  end
end
