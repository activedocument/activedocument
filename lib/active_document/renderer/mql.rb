# frozen_string_literal: true

module ActiveDocument
  module Renderer

    # Implementation details for parsing AST into MQL
    module MQL
      class << self

        FIELD_OPERATOR_NODES = {
          # comparison
          AST::Eq => '$eq',
          AST::Gt => '$gt',
          AST::Gte => '$gte',
          AST::AnyIn => '$in',
          AST::Lt => '$lt',
          AST::Lte => '$lte',
          AST::NotEq => '$ne',
          AST::NotIn => '$nin',
          # element
          AST::Exists => '$exists',
          AST::Type => '$type',
          # array
          AST::All => '$all',
          AST::ElemMatch => '$elemMatch',
          AST::Size => '$size',
          # evaluation
          AST::Expr => '$expr',
          AST::JsonSchema => '$jsonSchema',
          AST::Mod => '$mod',
          AST::Regex => '$regex',
          AST::Regexp => '$regexp',
          AST::Options => '$options',
          AST::Search => '$search',
          AST::Text => '$text',
          AST::Where => '$where',
          # bitwise
          AST::BitsAllClear => '$bitsAllClear',
          AST::BitsAllSet => '$bitsAllSet',
          AST::BitsAnyClear => '$bitsAnyClear',
          AST::BitsAnySet => '$bitsAnySet',
          # geospatial
          AST::GeoIntersects => '$geoIntersects',
          AST::GeoWithin => '$geoWithin',
          AST::Near => '$near',
          AST::MaxDistance => '$maxDistance',
          AST::NearSphere => '$nearSphere',
          # misc
          AST::Comment => '$comment'
        }.freeze

        LOGICAL_OPERATOR_NODES = {
          AST::And => '$and',
          AST::Nor => '$nor',
          AST::Not => '$not',
          AST::Or => '$or'
        }.freeze

        NODE_OPERATORS = [FIELD_OPERATOR_NODES, LOGICAL_OPERATOR_NODES].inject(&:merge).freeze

        def render(tree)
          return nil if tree.nil?
          return nil unless tree.is_a?(AST::Node)
          return nil if tree.empty?

          do_render(tree)
        end

        def do_render(node)
          case node
          when AST::Node
            do_render_node(node)
          when Array
            if primitive_items?(node)
              node
            else
              do_render(node)
            end
          when Numeric, String
            node
          end
        end

        private

        def do_render_node(node)
          left, right = *node.children

          case node
          when AST::FieldOperator
            { do_render(left) => { node_type(node) => do_render(right) } }
          when AST::LogicalOperator
            { node_type(node) => [left, right].map { |n| do_render(n) } }
          end
        end

        def node_type(node)
          NODE_OPERATORS.fetch(node.class)
        end

        def primitive_items?(data)
          data.all? do |item|
            item.is_a?(Integer) ||
              item.is_a?(Set) ||
              item.is_a?(Float) ||
              item.is_a?(String) ||
              item.is_a?(Symbol) ||
              item.is_a?(ActiveDocument::Boolean) ||
              item.is_a?(Regexp) ||
              item.is_a?(Range) ||
              item.is_a?(Time) ||
              item.is_a?(Date) ||
              item.is_a?(DateTime) ||
              item.is_a?(ActiveSupport::TimeWithZone) ||
              item.is_a?(ActiveDocument::StringifiedSymbol) ||
              item.is_a?(BSON::Binary) ||
              item.is_a?(BigDecimal)
          end
        end

      end
    end
  end
end
