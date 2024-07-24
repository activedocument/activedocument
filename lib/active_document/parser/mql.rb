# frozen_string_literal: true

module ActiveDocument
  module Parser

    # Implementation details for parsing MQL into an AST
    module MQL

      FIELD_OPERATORS = {
        # comparison
        '$eq' => AST::Eq,
        '$gt' => AST::Gt,
        '$gte' => AST::Gte,
        '$in' => AST::AnyIn,
        '$lt' => AST::Lt,
        '$lte' => AST::Lte,
        '$ne' => AST::NotEq,
        '$nin' => AST::NotIn,
        # element
        '$exists' => AST::Exists,
        '$type' => AST::Type,
        # array
        '$all' => AST::All,
        '$elemMatch' => AST::ElemMatch,
        '$size' => AST::Size,
        # evaluation
        '$expr' => AST::Expr,
        '$jsonSchema' => AST::JsonSchema,
        '$mod' => AST::Mod,
        '$regex' => AST::Regex,
        '$regexp' => AST::Regexp,
        '$options' => AST::Options,
        '$text' => AST::Text,
        '$search' => AST::Search,
        '$where' => AST::Where,
        # bitwise
        '$bitsAllClear' => AST::BitsAllClear,
        '$bitsAllSet' => AST::BitsAllSet,
        '$bitsAnyClear' => AST::BitsAnyClear,
        '$bitsAnySet' => AST::BitsAnySet,
        # geospatial
        '$geoIntersects' => AST::GeoIntersects,
        '$geoWithin' => AST::GeoWithin,
        '$near' => AST::Near,
        '$maxDistance' => AST::MaxDistance,
        '$nearSphere' => AST::NearSphere,
        # misc
        '$comment' => AST::Comment
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
          else
            raise BSON::Error::UnserializableClass if data.is_a?(Proc) # Proc is not serializable to a BSON type
            raise "unexpected data: #{data}" unless primitive_item?(data)

            op = path[-1]
            field = path[-2]
            value = data

            if LOGICAL_OPERATORS.key?(op)
              node_klass(op).new([field, value])
            else
              node_klass(op).new(field, value)
            end
          end
        end

        private

        def do_parse_hash(data, path = [])
          return nil if data == {}

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
              conds1 = if head.values[0].is_a?(Hash)
                         head.values[0].map { |v| { head.keys[0] => Hash[*v] } }
                       else
                         [head]
                       end

              conds = conds1 + conds2

              do_parse({ op => conds }, path)
            else

              left = do_parse(tail, path)
              right = do_parse(head, path)

              op = path.reverse.find { |p| LOGICAL_OPERATORS.key?(p) } || '$and'
              node_klass(op).new([left, right])
            end
          end
        end

        def do_parse_array(data, path = [])
          return nil if data == []

          # array of hashes, part of MQL syntax, indicates nested conditions
          if data.all?(Hash)

            if data == []
              op = path[-1]
              field = path[-2]
              value = data

              if LOGICAL_OPERATORS.key?(op)
                node_klass(op).new([field, value])
              else
                node_klass(op).new(field, value)
              end
            elsif data.size == 1
              do_parse(data[0], path)
            else
              head = data[0]
              tail = data[1..]

              left = do_parse(tail, path)
              right = do_parse(head, path)

              op = path.reverse.find { |p| LOGICAL_OPERATORS.key?(p) } || '$and'
              node_klass(op).new([left, right])
            end

          # primitive array, indicates terminal node
          # TODO: does it matter if we have in/nin in the path? It's a terminal node either way
          # elsif %w[$in $nin].include?(path[-1]) && primitive_items?(data)
          elsif primitive_items?(data)
            op = path[-1]
            field = path[-2]
            value = data

            if LOGICAL_OPERATORS.key?(op)
              node_klass(op).new([field, value])
            else
              node_klass(op).new(field, value)
            end

          # unexpected array
          else
            raise "unexpected array: #{data}"
          end
        end

        def primitive_items?(data)
          data.all? do |item|
            if item.is_a?(Array)
              primitive_items?(item)
            else
              primitive_item?(item)
            end
          end
        end

        def primitive_item?(item)
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
            item.is_a?(BigDecimal) ||
            item.is_a?(BSON::ObjectId) ||
            item.is_a?(NilClass) ||
            item.is_a?(BSON::Code) ||
            item.is_a?(BSON::Regexp::Raw) ||
            item.is_a?(BSON::Decimal128)
        end

        def node_klass(operator)
          OPERATORS.fetch(operator, AST::FieldOperator)
        end
      end
    end
  end
end
