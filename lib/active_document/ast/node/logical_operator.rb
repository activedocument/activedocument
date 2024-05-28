# frozen_string_literal: true

module ActiveDocument
  module AST

    # Base class for all logical operator nodes
    class LogicalOperator < Node
      alias_method :conditions, :children
    end
  end
end
