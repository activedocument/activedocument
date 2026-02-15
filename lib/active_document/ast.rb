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
require_relative 'ast/node/exists'
require_relative 'ast/node/type'
require_relative 'ast/node/all'
require_relative 'ast/node/elem_match'
require_relative 'ast/node/size'
require_relative 'ast/node/expr'
require_relative 'ast/node/json_schema'
require_relative 'ast/node/mod'
require_relative 'ast/node/regex'
require_relative 'ast/node/regexp'
require_relative 'ast/node/options'
require_relative 'ast/node/text'
require_relative 'ast/node/search'
require_relative 'ast/node/where'
require_relative 'ast/node/bits_all_clear'
require_relative 'ast/node/bits_all_set'
require_relative 'ast/node/bits_any_clear'
require_relative 'ast/node/bits_any_set'
require_relative 'ast/node/geo_intersects'
require_relative 'ast/node/geo_within'
require_relative 'ast/node/near'
require_relative 'ast/node/max_distance'
require_relative 'ast/node/near_sphere'
require_relative 'ast/node/comment'

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

    def Exists(*args)
      Exists.new(*args)
    end

    def Type(*args)
      Type.new(*args)
    end

    def All(*args)
      All.new(*args)
    end

    def ElemMatch(*args)
      ElemMatch.new(*args)
    end

    def Size(*args)
      Size.new(*args)
    end

    def Expr(*args)
      Expr.new(*args)
    end

    def JsonSchema(*args)
      JsonSchema.new(*args)
    end

    def Mod(*args)
      Mod.new(*args)
    end

    def Regex(*args)
      Regex.new(*args)
    end

    def Regexp(*args)
      Regexp.new(*args)
    end

    def Options(*args)
      Options.new(*args)
    end

    def Text(*args)
      Text.new(*args)
    end

    def Search(*args)
      Search.new(*args)
    end

    def Where(*args)
      Where.new(*args)
    end

    def BitsAllClear(*args)
      BitsAllClear.new(*args)
    end

    def BitsAllSet(*args)
      BitsAllSet.new(*args)
    end

    def BitsAnyClear(*args)
      BitsAnyClear.new(*args)
    end

    def BitsAnySet(*args)
      BitsAnySet.new(*args)
    end

    def GeoIntersects(*args)
      GeoIntersects.new(*args)
    end

    def GeoWithin(*args)
      GeoWithin.new(*args)
    end

    def Near(*args)
      Near.new(*args)
    end

    def MaxDistance(*args)
      MaxDistance.new(*args)
    end

    def NearSphere(*args)
      NearSphere.new(*args)
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

    def Comment(*args)
      Comment.new(*args)
    end

    # rubocop:enable Naming/MethodName

  end
end
