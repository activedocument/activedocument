# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module Queryable

      # Singleton module for normalizing query expressions.
      module QueryNormalizer
        extend self

        # Takes a criteria hash and expands Key objects into hashes containing
        # MQL corresponding to said key objects. Also converts the input to
        # BSON::Document to permit indifferent access.
        #
        # The argument must be a hash containing key-value pairs of the
        # following forms:
        # - { field_name: value }
        # - { 'field_name' => value }
        # - { :$operator => operator_value_expression }
        # - { '$operator' => operator_value_expression }
        #
        # This method effectively converts symbol keys to string keys in
        # the input +expr+, such that the downstream code can assume that
        # conditions always contain string keys.
        #
        # @param [ Hash ] expr Query expression including nested hashes.
        #
        # @return [ BSON::Document ] The expanded criteria.
        #
        # @api private
        # rubocop:disable Style/GuardClause
        def normalize_expr(expr, negating: false)
          unless expr.is_a?(Hash)
            raise ArgumentError.new('Argument must be a Hash')
          end

          result = BSON::Document.new
          expr.each do |field, value|
            QueryNormalizer.expr_part(field, value, negating: negating).each do |k, v|
              if (existing = result[k])
                if existing.is_a?(Hash)
                  # Existing value is an operator.
                  # If new value is also an operator, ensure there are no
                  # conflicts and add
                  if v.is_a?(Hash)
                    # The new value is also an operator.
                    # If there are no conflicts, combine the hashes, otherwise
                    # add new conditions to top level with $and.
                    if (v.keys & existing.keys).empty?
                      existing.merge!(v)
                    else
                      raise NotImplementedError.new('Ruby does not allow same symbol operator with different values')
                      # result['$and'] ||= []
                      # result['$and'] << { k => v }
                    end
                  else
                    # The new value is a simple value.
                    # Transform the implicit equality to either $eq or $regexp
                    # depending on the type of the argument. See
                    # https://www.mongodb.com/docs/manual/reference/operator/query/eq/#std-label-eq-usage-examples
                    # for the description of relevant server behavior.
                    op = case v
                         when Regexp, BSON::Regexp::Raw
                           '$regex'
                         else
                           '$eq'
                         end
                    # If there isn't an $eq/$regex operator already in the
                    # query, transform the new value into an operator
                    # expression and add it to the existing hash. Otherwise
                    # add the new condition with $and to the top level.
                    if existing.key?(op)
                      raise NotImplementedError.new('Ruby does not allow same symbol operator with different values')
                      # result['$and'] ||= []
                      # result['$and'] << { k => v }
                    else
                      existing.merge!(op => v)
                    end
                  end
                else
                  # Existing value is a simple value.
                  # See the notes above about transformations to $eq/$regex.
                  op = case existing
                       when Regexp, BSON::Regexp::Raw
                         '$regex'
                       else
                         '$eq'
                       end
                  if v.is_a?(Hash) && !v.key?(op)
                    result[k] = { op => existing }.update(v)
                  else
                    raise NotImplementedError.new('Ruby does not allow same symbol operator with different values')
                    # result['$and'] ||= []
                    # result['$and'] << { k => v }
                  end
                end
              else
                result[k] = v
              end
            end
          end
          result
        end
        # rubocop:enable Style/GuardClause

        # Get the value as a expression.
        #
        # @example Get the value as an expression.
        #   QueryNormalizer.expr_part('field', value)
        #
        # @param [ String | Symbol ] key The field key.
        # @param [ Object ] value The value of the criteria.
        # @param [ true | false ] negating If the selection should be negated.
        #
        # @return [ Hash ] The selection.
        #
        # @api private
        def expr_part(key, value, negating: false)
          if negating
            { key => { value.is_a?(Hash) || regexp?(value) ? '$not' : '$ne' => value } }
          else
            { key => value }
          end
        end

        # Expand criterion values to arrays, to be used with operators that
        # take an array as argument such as $in.
        #
        # @example Convert all the values to arrays.
        #   selectable.with_array_values({ key: 1...4 })
        #
        # @param [ Hash ] criterion The criterion.
        #
        # @return [ Hash ] The $in friendly criterion with array values.
        #
        # @api private
        def expand_condition_to_array_values(criterion)
          raise ArgumentError.new('Criterion cannot be nil here') if criterion.nil?

          criterion.transform_values { |value| to_array(value) }
        end

        private

        # Returns whether the object is Regexp-like.
        #
        # @param [ Object ] object The object to evaluate.
        #
        # @return [ Boolean ] Whether the object is Regexp-like.
        def regexp?(object)
          object.is_a?(Regexp) || object.is_a?(BSON::Regexp::Raw)
        end

        # Get the object as an array or wrapped by an array.
        #
        # @example Get the range as an array.
        #   QueryNormalizer.to_array(1...3)
        #
        # @return [ Array ] The object as an array.
        def to_array(object)
          case object
          when Array
            object
          when Range
            object.to_a
          else
            [object]
          end
        end
      end
    end
  end
end
