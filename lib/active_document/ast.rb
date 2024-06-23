# frozen_string_literal: true

# Base
require_relative 'ast/node'

# Field operators
require_relative 'ast/node/field_operator'
require_relative 'ast/node/any_in'
require_relative 'ast/node/eq'
require_relative 'ast/node/gt'
require_relative 'ast/node/gte'
require_relative 'ast/node/lt'
require_relative 'ast/node/lte'
require_relative 'ast/node/not_eq'
require_relative 'ast/node/not_in'

# Logical operators
require_relative 'ast/node/logical_operator'
require_relative 'ast/node/and'
require_relative 'ast/node/nor'
require_relative 'ast/node/not'
require_relative 'ast/node/or'

module ActiveDocument

  # Top-level module for AST structure
  module AST

    # rubocop:disable Naming/MethodName
    def AnyIn(*args)
      AnyIn.new(*args)
    end

    def Eq(*args)
      Eq.new(*args)
    end

    def Gt(*args)
      Gt.new(*args)
    end

    def Gte(*args)
      Gte.new(*args)
    end

    def Lt(*args)
      Lt.new(*args)
    end

    def Lte(*args)
      Lte.new(*args)
    end

    def NotEq(*args)
      NotEq.new(*args)
    end

    def NotIn(*args)
      NotIn.new(*args)
    end

    def And(*args)
      And.new(args)
    end

    def Nor(*args)
      Nor.new(args)
    end

    def Not(*args)
      Not.new(args)
    end

    def Or(*args)
      Or.new(args)
    end
    # rubocop:enable Naming/MethodName

  end
end
