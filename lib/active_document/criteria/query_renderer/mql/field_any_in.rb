# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module QueryAST
      # The AST node for a field "any in" condition.
      class FieldAnyIn < FieldOperator
      end
    end
  end
end
