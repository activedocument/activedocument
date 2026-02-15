# frozen_string_literal: true

module ActiveDocument
  module AST

    # Base class for all nodes in the AST
    class Node
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def ==(other)
        return false unless self.class == other.class

        children.sort_by(&:sort_cond).zip(other.children.sort_by(&:sort_cond)).all? { |child, other_child| child == other_child }
      end

      def empty?
        return true if children == []

        children.all?(&:empty?)
      end

      def self.name
        to_s.split('::')[-1]
      end

      def class_name
        self.class.name
      end

      def sort_cond
        class_name
      end

      def inspect(depth = 1)
        delimiter =
          if @children.any?(Node)
            "\n#{'  ' * depth}"
          else
            ' '
          end

        "(#{class_name}:#{delimiter}#{@children.map { |c| c.is_a?(Node) ? c.inspect(depth + 1) : c.inspect }.join(", #{delimiter}")})"
      end
    end

  end
end
