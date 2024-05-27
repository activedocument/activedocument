# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module QueryAST
      # The AST node base class for all field operators ("and", "or", "nor").
      class FieldOperator < Node
      end
    end
  end
end
