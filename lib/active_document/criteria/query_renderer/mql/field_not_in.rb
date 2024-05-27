# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module QueryAST
      # The AST node for an "not in" query.
      class FieldNotIn < FieldOperator
      end
    end
  end
end
