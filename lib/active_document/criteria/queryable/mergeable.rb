# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module Queryable

      # Contains behavior for merging existing selection with new selection.
      module Mergeable

        # Clear the current negating flag, used after cloning.
        #
        # @example Reset the state.
        #   mergeable.reset_state!
        #
        # @return [ ActiveDocument::Criteria ] self.
        def reset_state!
          self.negating = nil
          self
        end

        # Merge criteria with operators using the and operator.
        #
        # @param [ Hash ] criterion The criterion to add to the criteria.
        # @param [ String ] operator The MongoDB operator.
        #
        # @return [ ActiveDocument::Criteria ] The resulting criteria.
        def and_with_operator(criterion, operator)
          crit = self
          criterion&.each_pair do |field, value|
            val = prepare_for_merging(field, operator, value)
            # The prepare method already takes the negation into account. We
            # set negating to false here so that ``and`` doesn't also apply
            # negation and we have a double negative.
            crit.negating = false
            crit = crit.and(field => val)
          end
          crit
        end

        private

        # Adds $and/$or/$nor criteria to a copy of this selection.
        #
        # Each of the criteria can be a Hash of key/value pairs or MongoDB
        # operators (keys beginning with $), or a Selectable object
        # (which typically will be a Criteria instance).
        #
        # @api private
        #
        # @example Add the criterion.
        #   mergeable.__combine_criteria__([ 1, 2 ], "$in")
        #
        # @param [ Array<Hash | ActiveDocument::Criteria> ] criteria Multiple key/value pair
        #   matches or Criteria objects.
        # @param [ String ] operator The MongoDB operator.
        #
        # @return [ Mergeable ] The new mergeable.
        def __combine_criteria__(criteria, operator)
          clone.tap do |query|
            sel = query.selector
            criteria.flatten.each do |expr|
              next unless expr

              result_criteria = sel[operator] || []
              if expr.is_a?(Selectable)
                expr = expr.selector
              end
              normalized = QueryNormalizer.normalize_expr(expr, negating: negating?)
              sel.store(operator, result_criteria.push(normalized))
            end
          end
        end

        # Calling .flatten on an array which includes a Criteria instance
        # evaluates the criteria, which we do not want. Hence this method
        # explicitly only expands Array objects and Array subclasses.
        def __flatten_arrays__(array)
          out = []
          pending = array.dup
          until pending.empty?
            item = pending.shift
            if item.nil?
              # skip
            elsif item.is_a?(Array)
              pending += item
            else
              out << item
            end
          end
          out
        end

        # Prepare the value for merging.
        #
        # @api private
        #
        # @example Prepare the value.
        #   mergeable.prepare_for_merging("field", "$gt", 10)
        #
        # @param [ String ] field The name of the field.
        # @param [ Object ] value The value.
        #
        # @return [ Object ] The serialized value.
        def prepare_for_merging(field, operator, value)
          unless /exists|type|size/.match?(operator)
            field = field.to_s
            name = aliases[field] || field
            serializer = serializers[name]
            value = serializer.evolve(value) if serializer
          end
          selection = { operator => value }
          negating? ? { '$not' => selection } : selection
        end
      end
    end
  end
end
