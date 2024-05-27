# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module QueryAST
      # The AST node for a field "not equals" condition.
      class FieldNotEquals < FieldOperator
      end
    end
  end
end
