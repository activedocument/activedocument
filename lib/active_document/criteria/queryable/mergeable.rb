# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module Queryable

      # Contains behavior for merging existing selection with new selection.
      module Mergeable

        # @attribute [rw] strategy The name of the current strategy.
        attr_accessor :strategy

        # Instruct the next mergeable call to use intersection.
        #
        # @example Use intersection on the next call.
        #   mergeable.intersect.in(field: [ 1, 2, 3 ])
        #
        # @return [ Mergeable ] The intersect flagged mergeable.
        def intersect
          use(:__intersect__)
        end

        # Instruct the next mergeable call to use override.
        #
        # @example Use override on the next call.
        #   mergeable.override.in(field: [ 1, 2, 3 ])
        #
        # @return [ Mergeable ] The override flagged mergeable.
        def override
          use(:__override__)
        end

        # Instruct the next mergeable call to use union.
        #
        # @example Use union on the next call.
        #   mergeable.union.in(field: [ 1, 2, 3 ])
        #
        # @return [ Mergeable ] The union flagged mergeable.
        def union
          use(:__union__)
        end

        # Clear the current strategy and negating flag, used after cloning.
        #
        # @example Reset the strategies.
        #   mergeable.reset_strategies!
        #
        # @return [ ActiveDocument::Criteria ] self.
        def reset_strategies!
          self.strategy = nil
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
            val = prepare(field, operator, value)
            # The prepare method already takes the negation into account. We
            # set negating to false here so that ``and`` doesn't also apply
            # negation and we have a double negative.
            crit.negating = false
            crit = crit.and(field => val)
          end
          crit
        end

        private

        # Adds the criterion to the existing selection.
        #
        # @api private
        #
        # @example Add the criterion.
        #   mergeable.__add__({ name: 1 }, "$in")
        #
        # @param [ Hash ] criterion The criteria.
        # @param [ String ] operator The MongoDB operator.
        #
        # @return [ Mergeable ] The new mergeable.
        def __add__(criterion, operator)
          with_strategy(:__add__, criterion, operator)
        end

        # Adds the criterion to the existing selection.
        #
        # @api private
        #
        # @example Add the criterion.
        #   mergeable.__expanded__([ 1, 10 ], "$within", "$center")
        #
        # @param [ Hash ] criterion The criteria.
        # @param [ String ] outer The outer MongoDB operator.
        # @param [ String ] inner The inner MongoDB operator.
        #
        # @return [ Mergeable ] The new mergeable.
        def __expanded__(criterion, outer, inner)
          selection(criterion) do |selector, field, value|
            selector.store(field, { outer => { inner => value } })
          end
        end

        # Adds the criterion to the existing selection.
        #
        # @api private
        #
        # @example Add the criterion.
        #   mergeable.__intersect__([ 1, 2 ], "$in")
        #
        # @param [ Hash ] criterion The criteria.
        # @param [ String ] operator The MongoDB operator.
        #
        # @return [ Mergeable ] The new mergeable.
        def __intersect__(criterion, operator)
          with_strategy(:__intersect__, criterion, operator)
        end

        # Adds $and/$or/$nor criteria to a copy of this selection.
        #
        # Each of the criteria can be a Hash of key/value pairs or MongoDB
        # operators (keys beginning with $), or a Selectable object
        # (which typically will be a Criteria instance).
        #
        # @api private
        #
        # @example Add the criterion.
        #   mergeable.__multi__([ 1, 2 ], "$in")
        #
        # @param [ Array<Hash | ActiveDocument::Criteria> ] criteria Multiple key/value pair
        #   matches or Criteria objects.
        # @param [ String ] operator The MongoDB operator.
        #
        # @return [ Mergeable ] The new mergeable.
        def __multi__(criteria, operator)
          clone.tap do |query|
            sel = query.selector
            criteria.flatten.each do |expr|
              next unless expr

              result_criteria = sel[operator] || []
              if expr.is_a?(Selectable)
                expr = expr.selector
              end
              normalized = QueryNormalizer.normalize_expr(self, expr)
              sel.store(operator, result_criteria.push(normalized))
            end
          end
        end

        # Combines criteria into a MongoDB selector.
        #
        # Criteria is an array of criterion objects which will be flattened.
        #
        # Each criterion can be:
        # - A hash
        # - A Criteria instance
        # - nil, in which case it is ignored
        #
        # @api private
        def _active_document_add_top_level_operation(operator, criteria)
          # Flatten the criteria. The idea is that predicates in MongoDB
          # are always hashes and are never arrays. This method additionally
          # allows Criteria instances as predicates.
          # The flattening is existing ActiveDocument behavior but we could possibly
          # get rid of it as applications can splat their predicates, or
          # flatten if needed.
          clone.tap do |query|
            sel = query.selector
            _active_document_flatten_arrays(criteria).each do |criterion|
              expr = if criterion.is_a?(Selectable)
                       QueryNormalizer.normalize_expr(self, criterion.selector)
                     else
                       QueryNormalizer.normalize_expr(self, criterion)
                     end
              if sel.empty?
                sel.store(operator, [expr])
              elsif sel.keys == [operator]
                sel.store(operator, sel[operator] + [expr])
              else
                operands = [sel.dup] + [expr]
                sel.clear
                sel.store(operator, operands)
              end
            end
          end
        end

        # Calling .flatten on an array which includes a Criteria instance
        # evaluates the criteria, which we do not want. Hence this method
        # explicitly only expands Array objects and Array subclasses.
        def _active_document_flatten_arrays(array)
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

        # Adds the criterion to the existing selection.
        #
        # @api private
        #
        # @example Add the criterion.
        #   mergeable.__override__([ 1, 2 ], "$in")
        #
        # @param [ Hash | ActiveDocument::Criteria ] criterion The criteria.
        # @param [ String ] operator The MongoDB operator.
        #
        # @return [ Mergeable ] The new mergeable.
        def __override__(criterion, operator)
          criterion = criterion.selector if criterion.is_a?(Selectable)
          selection(criterion) do |selector, field, value|
            expression = prepare(field, operator, value)
            existing = selector[field]
            if existing.respond_to?(:merge!)
              selector.store(field, existing.merge!(expression))
            else
              selector.store(field, expression)
            end
          end
        end

        # Adds the criterion to the existing selection.
        #
        # @api private
        #
        # @example Add the criterion.
        #   mergeable.__union__([ 1, 2 ], "$in")
        #
        # @param [ Hash ] criterion The criteria.
        # @param [ String ] operator The MongoDB operator.
        #
        # @return [ Mergeable ] The new mergeable.
        def __union__(criterion, operator)
          with_strategy(:__union__, criterion, operator)
        end

        # Use the named strategy for the next operation.
        #
        # @api private
        #
        # @example Use intersection.
        #   mergeable.use(:__intersect__)
        #
        # @param [ Symbol ] strategy The strategy to use.
        #
        # @return [ Mergeable ] The existing mergeable.
        def use(strategy)
          tap do |mergeable|
            mergeable.strategy = strategy
          end
        end

        # Add criterion to the selection with the named strategy.
        #
        # @api private
        #
        # @example Add criterion with a strategy.
        #   mergeable.with_strategy(:__union__, {field_name: [ 1, 2, 3 ]}, "$in")
        #
        # @param [ Symbol ] strategy The name of the strategy method.
        # @param [ Object ] criterion The criterion to add.
        # @param [ String ] operator The MongoDB operator.
        #
        # @return [ Mergeable ] The cloned query.
        def with_strategy(strategy, criterion, operator)
          selection(criterion) do |selector, field, value|
            selector.store(
              field,
              selector[field].send(strategy, prepare(field, operator, value))
            )
          end
        end

        # Prepare the value for merging.
        #
        # @api private
        #
        # @example Prepare the value.
        #   mergeable.prepare("field", "$gt", 10)
        #
        # @param [ String ] field The name of the field.
        # @param [ Object ] value The value.
        #
        # @return [ Object ] The serialized value.
        def prepare(field, operator, value)
          unless /exists|type|size/.match?(operator)
            value = QueryNormalizer.expand_complex(value)
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
