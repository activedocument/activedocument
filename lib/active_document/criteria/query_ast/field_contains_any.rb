# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module QueryAST
      # The AST node for an array field "contains any" condition.
      # In MongoDB, this is synonymous with the "any in" ($in) operator.
      class FieldContainsAny < FieldAnyIn
      end
    end
  end
end
