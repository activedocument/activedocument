# frozen_string_literal: true

module ActiveDocument
  module Parser

    # Implementation details for parsing MQL into an AST
    module MQL

      FIELD_OPERATORS = {
        '$eq' => AST::Eq,
        '$gt' => AST::Gt,
        '$gte' => AST::Gte,
        '$in' => AST::AnyIn,
        '$lt' => AST::Lt,
        '$lte' => AST::Lte,
        '$ne' => AST::NotEq,
        '$nin' => AST::NotIn
      }.freeze

      LOGICAL_OPERATORS = {
        '$and' => AST::And,
        '$nor' => AST::Nor,
        '$not' => AST::Not,
        '$or' => AST::Or
      }.freeze

      OPERATORS = [FIELD_OPERATORS, LOGICAL_OPERATORS].inject(&:merge).freeze

      class << self

        def parse(mql_hash)
          return nil if mql_hash.nil?
          return nil unless mql_hash.is_a?(Hash)
          return nil if mql_hash == {}

          do_parse(mql_hash)
        end

        def do_parse(data, path = [])
          case data
          when Hash
            do_parse_hash(data, path)
          when Array
            do_parse_array(data, path)
          # when NilClass
          #   data
          when Numeric
            op = path[-1]
            field = path[-2]
            value = data
            node_klass(op).new(field, value)
          else
            raise "unexpected data: #{data}"
          end
        end

        private

        def do_parse_hash(data, path = [])
          # require 'pry'; require 'pry-nav'; binding.pry
          if data.size == 1
            if path[-1] == '$not'
              node_klass('$not').new([do_parse(data.values[0], path + [data.keys[0]])])
            else
              do_parse(data.values[0], path + [data.keys[0]])
            end
          else
            head = data.select.with_index { |_, i| i == 0 }
            tail = data.reject.with_index { |_, i| i == 0 }

            # detect implicit MQL syntax {field => conds1, $op => [conds2]}
            # and convert it to explicit MQL syntax {$op => [{field => cond1}, {field => cond2}, ...]}
            if tail.size == 1 && tail.keys[0].start_with?('$') && tail.values[0].is_a?(Array) && tail.values[0].all?(Hash)

              op = tail.keys[0]
              conds2 = tail.values[0]
              conds1 = head.values[0].map { |v| { head.keys[0] => Hash[*v] } }
              conds = conds1 + conds2

              do_parse({ op => conds }, path)

            else

              left = do_parse(tail, path)
              right = do_parse(head, path)

              op = path.reverse.find { |p| p.start_with?('$') } || '$and'
              node_klass(op).new([left, right])
            end
          end
        end

        def do_parse_array(data, path = [])
          # array of hashes, part of MQL syntax, indicates nested conditions
          if data.all?(Hash)

            if data.size == 1
              do_parse(data[0], path)
            else
              head = data[0]
              tail = data[1..]

              left = do_parse(tail, path)
              right = do_parse(head, path)

              op = path.reverse.find { |p| p.start_with?('$') } || '$and'
              node_klass(op).new([left, right])
            end

          # primitive array, indicates terminal node
          elsif %w[$in $nin].include?(path[-1]) && primitive_items?(data)
            op = path[-1]
            field = path[-2]
            value = data

            node_klass(op).new(field, value)

          # unexpected array
          else
            raise "unexpected array: #{data}"
          end
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

        def node_klass(operator)
          OPERATORS.fetch(operator)
        end
      end
    end
  end
end
