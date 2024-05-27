# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module QueryAST
      # Used for non-field, non-logical operator conditions
      # such as MQL "$where" conditions.
      class OperatorCondition < Node
      end
    end
  end
end
