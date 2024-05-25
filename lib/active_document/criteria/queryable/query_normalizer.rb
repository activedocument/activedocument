# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module Queryable
      module QueryNormalizer
        extend self

        # Takes a criteria hash and expands Key objects into hashes containing
        # MQL corresponding to said key objects. Also converts the input to
        # BSON::Document to permit indifferent access.
        #
        # The argument must be a hash containing key-value pairs of the
        # following forms:
        # - {field_name: value}
        # - {'field_name' => value}
        # - {key_instance: value}
        # - {:$operator => operator_value_expression}
        # - {'$operator' => operator_value_expression}
        #
        # This method effectively converts symbol keys to string keys in
        # the input +expr+, such that the downstream code can assume that
        # conditions always contain string keys.
        #
        # @param [ Hash ] expr Query expression including nested hashes.
        #
        # @return [ BSON::Document ] The expanded criteria.
        def normalize_expr(query, expr)
          unless expr.is_a?(Hash)
            raise ArgumentError.new('Argument must be a Hash')
          end

          result = BSON::Document.new
          expr.each do |field, value|
            QueryNormalizer.expr_part(field, QueryNormalizer.expand_complex(value), query.negating?).each do |k, v|
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
                      existing.update(v)
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
                      existing.update(op => v)
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
        def expr_part(key, value, negating = false)
          if negating
            { key => { regexp?(value) ? '$not' : '$ne' => value } }
          else
            { key => value }
          end
        end

        # Get the object as expanded.
        #
        # @example Get the object expanded.
        #   QueryNormalizer.expand_complex(object)
        #
        # @return [ Object ] The expanded object.
        def expand_complex(object)
          case object
          when Array
            object.map { |value| expand_complex(value) }
          when Hash
            replacement = {}
            object.each_pair do |key, value|
              replacement.merge!(expr_part(key, expand_complex(value)))
            end
            replacement
          else
            object
          end
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
      end
    end
  end
end
