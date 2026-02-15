# frozen_string_literal: true

module ActiveDocument
  module AST

    # Base class for all field operator nodes
    class FieldOperator < Node
      attr_reader :field, :value

      def initialize(field, value)
        @field = field
        @value = value
        super([])
      end

      def children
        [field, value]
      end

      def ==(other)
        return false unless self.class == other.class

        field == other.field && value == other.value
      end

      def empty?
        return true if field.nil?

        false
      end

      def sort_cond
        [class_name, field, value].join('-')
      end

      def inspect(_depth = 1)
        "(#{class_name}: field=#{@field.inspect}, value=#{@value})"
      end
    end
  end
end
