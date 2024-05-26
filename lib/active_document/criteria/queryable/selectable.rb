# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module Queryable

      # An queryable selectable is selectable, in that it has the ability to select
      # document from the database. The selectable module brings all functionality
      # to the selectable that has to do with building MongoDB selectors.
      module Selectable # rubocop:disable Metrics/ModuleLength

        # @attribute [rw] negating If the next expression is negated.
        # @attribute [rw] selector The query selector.
        attr_accessor :negating, :selector

        # Clear the current negating flag, used after cloning.
        #
        # @example Reset the state.
        #   selectable.reset_state!
        #
        # @return [ ActiveDocument::Criteria ] self.
        def reset_state!
          self.negating = nil
          self
        end

        # Add the $all criterion.
        #
        # @example Add the criterion.
        #   selectable.all(field: [ 1, 2 ])
        #
        # @example Execute an $all in a where query.
        #   selectable.where(field: { '$all' => [ 1, 2 ] })
        #
        # @param [ Hash... ] *criteria The key value pair(s) for $all matching.
        #
        # @return [ Selectable ] The cloned selectable.
        def all(*criteria)
          return clone.tap(&:reset_state!) if criteria.empty?

          raise ArgumentError.new('Use #contains_all instead of #all for to match all array values')
        end

        # Add the $all criterion to match all values in the array.
        #
        # @example Add the criterion.
        #   selectable.all(field: [ 1, 2 ])
        #
        # @example Execute an $all in a where query.
        #   selectable.where(field: { '$all' => [ 1, 2 ] })
        #
        # @param [ Hash... ] *criteria The key value pair(s) for $all matching.
        #
        # @return [ Selectable ] The cloned selectable.
        def contains_all(*criteria)
          raise Errors::CriteriaArgumentRequired.new(:contains_all) if criteria.empty?

          criteria.inject(clone) do |query, condition|
            raise Errors::CriteriaArgumentRequired.new(:contains_all) if condition.nil?

            condition = QueryNormalizer.expand_condition_to_array_values(condition)
            condition.inject(query) do |q, (field, value)|
              v = { '$all' => value }
              v = { '$not' => v } if negating?
              q.add_field_expression(field.to_s, v)
            end
          end.reset_state!
        end

        # Add the $and criterion.
        #
        # @example Add the criterion.
        #   selectable.and({ field: value }, { other: value })
        #
        # @param [ [ Hash | ActiveDocument::Criteria | Array<Hash | ActiveDocument::Criteria> ]... ] *criteria
        #   Multiple key/value pair matches or Criteria objects that all must
        #   match to return results.
        #
        # @return [ Selectable ] The new selectable.
        def and(*criteria)
          flatten_args(criteria).inject(clone) do |c, new_s|
            new_s = new_s.selector if new_s.is_a?(Selectable)
            normalized = QueryNormalizer.normalize_expr(new_s, negating: negating?)
            normalized.each do |k, v|
              k = k.to_s
              if c.selector[k]
                # There is already a condition on k.
                # If v is an operator, and all existing conditions are
                # also operators, and v isn't present in existing conditions,
                # we can add to existing conditions.
                # Otherwise use $and.
                if v.is_a?(Hash) &&
                   v.length == 1 &&
                   (new_k = v.keys.first).start_with?('$') &&
                   (existing_kv = c.selector[k]).is_a?(Hash) &&
                   !existing_kv.key?(new_k) &&
                   existing_kv.keys.all? { |sub_k| sub_k.start_with?('$') }
                  merged_v = c.selector[k].merge(v)
                  c.selector.store(k, merged_v)
                else
                  c = c.send(:__combine_criteria__, [k => v], '$and')
                end
              else
                c.selector.store(k, v)
              end
            end
            c
          end
        end
        alias_method :all_of, :and

        # Add the range selection.
        #
        # @example Match on results within a single range.
        #   selectable.between(field: 1..2)
        #
        # @example Match on results between multiple ranges.
        #   selectable.between(field: 1..2, other: 5..7)
        #
        # @param [ Hash ] criterion Multiple key/range pairs.
        #
        # @return [ Selectable ] The cloned selectable.
        # TODO: this needs to support inclusive an exclusive range
        def between(criterion)
          raise Errors::CriteriaArgumentRequired.new(:between) if criterion.nil?

          # TODO: this will override existing conditions on the field
          clone.tap do |query|
            criterion&.each_pair do |field, value|
              query.selector.store(
                field,
                { '$gte' => value.min, '$lte' => value.max }
              )
            end
            query.reset_state!
          end
        end

        # Select with an $elemMatch.
        #
        # @example Add criterion for a single match.
        #   selectable.elem_match(field: { name: "value" })
        #
        # @example Add criterion for multiple matches.
        #   selectable.elem_match(
        #     field: { name: "value" },
        #     other: { name: "value"}
        #   )
        #
        # @example Execute an $elemMatch in a where query.
        #   selectable.where(field: { '$elemMatch' => { name: 'value' } })
        #
        # @param [ Hash ] criterion The field/match pairs.
        #
        # @return [ Selectable ] The cloned selectable.
        def elem_match(criterion)
          raise Errors::CriteriaArgumentRequired.new(:elem_match) if criterion.nil?

          and_with_operator(criterion, '$elemMatch')
        end

        # Add the $exists selection.
        #
        # @example Add a single selection.
        #   selectable.exists(field: true)
        #
        # @example Add multiple selections.
        #   selectable.exists(field: true, other: false)
        #
        # @example Execute an $exists in a where query.
        #   selectable.where(field: { '$exists' => true })
        #
        # @param [ Hash ] criterion The field/boolean existence checks.
        #
        # @return [ Selectable ] The cloned selectable.
        def exists(criterion)
          raise Errors::CriteriaArgumentRequired.new(:exists) if criterion.nil?

          and_with_operator(criterion, '$exists')
        end

        # Add a $geoIntersects or $geoWithin selection. Symbol operators must
        # be used as shown in the examples to expand the criteria.
        #
        # @note Refer to Geospatial Query Operators
        #   https://www.mongodb.com/docs/manual/reference/operator/query-geospatial/
        #
        # @example Add a geo intersect criterion for a line.
        #   query.geo_spatial(location: { '$geoIntersects' => { '$geometry' => { type: 'LineString', coordinates: [[1, 10], [2, 10]] } } })
        #
        # @example Add a geo intersect criterion for a point.
        #   query.geo_spatial(location: { '$geoIntersects' => { '$geometry' => { type: 'Point', coordinates: [1, 10] } } })
        #
        # @example Add a geo intersect criterion for a polygon.
        #   query.geo_spatial(location: { '$geoIntersects' => { '$geometry' => { type: 'Polygon', coordinates: [[1, 10], [2, 10], [1, 5]] } } })
        #
        # @example Add a geo within criterion for a polygon.
        #   query.geo_spatial(location: { '$geoWithin' => { '$geometry' => { type: 'Polygon', coordinates: [[1, 10], [2, 10], [1, 5]] } } })
        #
        # @param [ Hash ] criterion The criterion.
        #
        # @return [ Selectable ] The cloned selectable.
        def geo_spatial(criterion)
          raise Errors::CriteriaArgumentRequired.new(:geo_spatial) if criterion.nil?

          # Merge the criterion into the selection
          # TODO: check if this overrides existing conditions on the field
          clone.tap do |query|
            criterion&.each_pair do |field, value|
              query.selector.merge!(field.to_s => value.deep_stringify_keys)
            end
            query.reset_state!
          end
        end

        # Add the $eq criterion to the selector.
        #
        # @example Add the $eq criterion.
        #   selectable.eq(age: 60)
        #
        # @example Execute an $eq in a where query.
        #   selectable.where(field: { '$eq' => 10 })
        #
        # @param [ Hash ] criterion The field/value pairs to check.
        #
        # @return [ Selectable ] The cloned selectable.
        def eq(criterion)
          raise Errors::CriteriaArgumentRequired.new(:eq) if criterion.nil?

          and_with_operator(criterion, '$eq')
        end

        # Add the $gt criterion to the selector.
        #
        # @example Add the $gt criterion.
        #   selectable.gt(age: 60)
        #
        # @example Execute an $gt in a where query.
        #   selectable.where(field: { '$gt' => 10 })
        #
        # @param [ Hash ] criterion The field/value pairs to check.
        #
        # @return [ Selectable ] The cloned selectable.
        def gt(criterion)
          raise Errors::CriteriaArgumentRequired.new(:gt) if criterion.nil?

          and_with_operator(criterion, '$gt')
        end

        # Add the $gte criterion to the selector.
        #
        # @example Add the $gte criterion.
        #   selectable.gte(age: 60)
        #
        # @example Execute an $gte in a where query.
        #   selectable.where(field: { '$gte' => 10 })
        #
        # @param [ Hash ] criterion The field/value pairs to check.
        #
        # @return [ Selectable ] The cloned selectable.
        def gte(criterion)
          raise Errors::CriteriaArgumentRequired.new(:gte) if criterion.nil?

          and_with_operator(criterion, '$gte')
        end

        # Adds the $in selection to the selectable.
        #
        # @example Add $in selection on an array.
        #   selectable.in(age: [ 1, 2, 3 ])
        #
        # @example Add $in selection on a range.
        #   selectable.in(age: 18..24)
        #
        # @example Execute an $in in a where query.
        #   selectable.where(field: { '$in' => [ 1, 2, 3 ] })
        #
        # @param [ Hash ] condition The field/value criterion pairs.
        #
        # @return [ Selectable ] The cloned selectable.
        def any_in(condition)
          raise Errors::CriteriaArgumentRequired.new(:any_in) if condition.nil?

          condition = QueryNormalizer.expand_condition_to_array_values(condition)
          condition.inject(clone) do |query, (field, value)|
            v = { '$in' => value }
            v = { '$not' => v } if negating?
            query.add_field_expression(field.to_s, v)
          end.reset_state!
        end
        alias_method :contains_any, :any_in

        # Add the $lt criterion to the selector.
        #
        # @example Add the $lt criterion.
        #   selectable.lt(age: 60)
        #
        # @example Execute an $lt in a where query.
        #   selectable.where(field: { '$lt' => 10 })
        #
        # @param [ Hash ] criterion The field/value pairs to check.
        #
        # @return [ Selectable ] The cloned selectable.
        def lt(criterion)
          raise Errors::CriteriaArgumentRequired.new(:lt) if criterion.nil?

          and_with_operator(criterion, '$lt')
        end

        # Add the $lte criterion to the selector.
        #
        # @example Add the $lte criterion.
        #   selectable.lte(age: 60)
        #
        # @example Execute an $lte in a where query.
        #   selectable.where(field: { '$lte' => 10 })
        #
        # @param [ Hash ] criterion The field/value pairs to check.
        #
        # @return [ Selectable ] The cloned selectable.
        def lte(criterion)
          raise Errors::CriteriaArgumentRequired.new(:lte) if criterion.nil?

          and_with_operator(criterion, '$lte')
        end

        # Add a $maxDistance selection to the selectable.
        #
        # @example Add the $maxDistance selection.
        #   selectable.max_distance(location: 10)
        #
        # @param [ Hash ] criterion The field/distance pairs.
        #
        # @return [ Selectable ] The cloned selectable.
        def max_distance(criterion)
          raise Errors::CriteriaArgumentRequired.new(:max_distance) if criterion.nil?

          # $maxDistance must be given together with $near
          and_with_operator(criterion, '$maxDistance')
        end

        # Adds $mod selection to the selectable.
        #
        # @example Add the $mod selection.
        #   selectable.mod(field: [ 10, 1 ])
        #
        # @example Execute an $mod in a where query.
        #   selectable.where(field: { '$mod' => [ 10, 1 ] })
        #
        # @param [ Hash ] criterion The field/mod selections.
        #
        # @return [ Selectable ] The cloned selectable.
        def mod(criterion)
          raise Errors::CriteriaArgumentRequired.new(:mod) if criterion.nil?

          and_with_operator(criterion, '$mod')
        end

        # Adds $ne selection to the selectable.
        #
        # @example Query for a value $ne to something.
        #   selectable.ne(field: 10)
        #
        # @example Execute an $ne in a where query.
        #   selectable.where(field: { '$ne' => 'value' })
        #
        # @param [ Hash ] criterion The field/ne selections.
        #
        # @return [ Selectable ] The cloned selectable.
        def ne(criterion)
          raise Errors::CriteriaArgumentRequired.new(:ne) if criterion.nil?

          and_with_operator(criterion, '$ne')
        end
        alias_method :excludes, :ne

        # Adds a $near criterion to a geo selection.
        #
        # @example Add the $near selection.
        #   selectable.near(location: [ 23.1, 12.1 ])
        #
        # @example Execute an $near in a where query.
        #   selectable.where(field: { '$near' => [ 23.2, 12.1 ] })
        #
        # @param [ Hash ] criterion The field/location pair.
        #
        # @return [ Selectable ] The cloned selectable.
        def near(criterion)
          raise Errors::CriteriaArgumentRequired.new(:near) if criterion.nil?

          and_with_operator(criterion, '$near')
        end

        # Adds a $nearSphere criterion to a geo selection.
        #
        # @example Add the $nearSphere selection.
        #   selectable.near_sphere(location: [ 23.1, 12.1 ])
        #
        # @example Execute an $nearSphere in a where query.
        #   selectable.where(field: { '$nearSphere' => [ 10.11, 3.22 ] })
        #
        # @param [ Hash ] criterion The field/location pair.
        #
        # @return [ Selectable ] The cloned selectable.
        def near_sphere(criterion)
          raise Errors::CriteriaArgumentRequired.new(:near_sphere) if criterion.nil?

          and_with_operator(criterion, '$nearSphere')
        end

        # Adds the $nin selection to the selectable.
        #
        # @example Add $nin selection on an array.
        #   selectable.nin(age: [ 1, 2, 3 ])
        #
        # @example Add $nin selection on a range.
        #   selectable.nin(age: 18..24)
        #
        # @example Execute an $nin in a where query.
        #   selectable.where(field: { '$nin' => [ 1, 2, 3 ] })
        #
        # @param [ Hash ] condition The field/value criterion pairs.
        #
        # @return [ Selectable ] The cloned selectable.
        def nin(condition)
          raise Errors::CriteriaArgumentRequired.new(:nin) if condition.nil?

          condition = QueryNormalizer.expand_condition_to_array_values(condition)
          condition.inject(clone) do |query, (field, value)|
            v = { '$nin' => value }
            v = { '$not' => v } if negating?
            query.add_field_expression(field.to_s, v)
          end.reset_state!
        end
        alias_method :not_in, :nin
        alias_method :contains_none, :nin

        # Is the current selectable negating the next selection?
        #
        # @example Is the selectable negating?
        #   selectable.negating?
        #
        # @return [ true | false ] If the selectable is negating.
        def negating?
          !!negating
        end

        # Negate the arguments, or the next selection if no arguments are given.
        #
        # @example Negate the next selection.
        #   selectable.not.in(field: [ 1, 2 ])
        #
        # @example Add the $not criterion.
        #   selectable.not(name: /Bob/)
        #
        # @example Execute a $not in a where query.
        #   selectable.where(field: { '$not' => /Bob/ })
        #
        # @param [ [ Hash | ActiveDocument::Criteria ]... ] *criteria The key/value pair
        #   matches or Criteria objects to negate.
        #
        # @return [ Selectable ] The new selectable.
        def not(*criteria)
          if criteria.empty?
            dup.tap { |query| query.negating = true }
          else
            criteria.compact.inject(clone) do |c, new_s|
              new_s = new_s.selector if new_s.is_a?(Selectable)
              QueryNormalizer.normalize_expr(new_s, negating: negating?).each do |k, v|
                k = k.to_s
                if c.selector[k] || k.start_with?('$') || v.is_a?(Hash)
                  c = c.send(:__combine_criteria__, [{ '$nor' => [{ k => v }] }], '$and')
                else
                  negated_operator = if v.is_a?(Regexp)
                                       '$not'
                                     else
                                       '$ne'
                                     end
                  c = c.send(:__override__, { k => v }, negated_operator)
                end
              end
              c
            end
          end
        end

        # TODO: only used by #not. check if this can be removed.
        def __override__(criterion, operator)
          clone.tap do |query|
            criterion&.each_pair do |field, value|
              selector = query.selector
              field = field.to_s
              expression = prepare_for_merging(field, operator, value)
              existing = selector[field]
              if existing.respond_to?(:merge!)
                selector.store(field, existing.merge!(expression))
              else
                selector.store(field, expression)
              end
            end
            query.reset_state!
          end
        end

        # Negate the arguments, constraining the query to only those documents
        # that do NOT match the arguments.
        #
        # @example Exclude a single criterion.
        #   selectable.none_of(name: /Bob/)
        #
        # @example Exclude multiple criteria.
        #   selectable.none_of(name: /Bob/, country: "USA")
        #
        # @example Exclude multiple criteria as an array.
        #   selectable.none_of([{ name: /Bob/ }, { country: "USA" }])
        #
        # @param [ [ Hash | ActiveDocument::Criteria ]... ] *criteria The key/value pair
        #   matches or Criteria objects to negate.
        #
        # @return [ Selectable ] The new selectable.
        def none_of(*criteria)
          criteria = flatten_args(criteria)
          return dup if criteria.empty?

          exprs = criteria.map do |criterion|
            QueryNormalizer.normalize_expr(
              criterion.is_a?(Selectable) ? criterion.selector : criterion,
              negating: negating?
            )
          end

          self.and('$nor' => exprs)
        end

        # Adds a disjunction of the arguments as an additional constraint
        # to the criteria already existing in the receiver.
        #
        # Use +or+ to make the receiver one of the disjunction operands.
        #
        # Each argument can be a Hash, a Criteria object, an array of
        # Hash or Criteria objects, or a nested array. Nested arrays will be
        # flattened and can be of any depth. Passing arrays is deprecated.
        #
        # @example Add the $or selection where both fields must have the specified values.
        #   selectable.any_of(field: 1, field: 2)
        #
        # @example Add the $or selection where either value match is sufficient.
        #   selectable.any_of({field: 1}, {field: 2})
        #
        # @example Same as previous example but using the deprecated array wrap.
        #   selectable.any_of([{field: 1}, {field: 2}])
        #
        # @example Same as previous example, also deprecated.
        #   selectable.any_of([{field: 1}], [{field: 2}])
        #
        # @param [ [ Hash | ActiveDocument::Criteria | Array<Hash | ActiveDocument::Criteria> ]... ] *criteria
        #   Multiple key/value pair matches or Criteria objects, or arrays
        #   thereof. Passing arrays is deprecated.
        #
        # @return [ Selectable ] The new selectable.
        def any_of(*criteria)
          criteria = flatten_args(criteria)
          case criteria.length
          when 0
            clone
          when 1
            # When we have a single criteria, any_of behaves like and.
            # Note: criteria can be a Query object, which #where method does
            # not support.
            self.and(*criteria)
          else
            # When we have multiple criteria, combine them all with $or
            # and add the result to self.
            exprs = criteria.map do |criterion|
              if criterion.is_a?(Selectable)
                QueryNormalizer.normalize_expr(criterion.selector, negating: negating?)
              else
                criterion.to_h do |k, v|
                  if k.is_a?(Symbol)
                    [k.to_s, v]
                  else
                    [k, v]
                  end
                end
              end
            end
            self.and('$or' => exprs)
          end
        end

        # Add a $size selection for array fields.
        #
        # @example Add the $size selection.
        #   selectable.size_of(field: 5)
        #
        # @note This method is named #size_of not to conflict with any existing
        #   #size method on enumerables or symbols.
        #
        # @example Execute an $size in a where query.
        #   selectable.where(field: { '$size' => 10 })
        #
        # @param [ Hash ] criterion The field/size pairs criterion.
        #
        # @return [ Selectable ] The cloned selectable.
        def size_of(criterion)
          raise Errors::CriteriaArgumentRequired.new(:size_of) if criterion.nil?

          and_with_operator(criterion, '$size')
        end

        # Adds a $type selection to the selectable.
        #
        # @example Add the $type selection.
        #   selectable.type_of(field: 15)
        #
        # @example Execute an $type in a where query.
        #   selectable.where(field: { '$type' => 15 })
        #
        # @note https://www.mongodb.com/docs/manual/reference/bson-types/
        #   contains a list of all types.
        #
        # @param [ Hash ] criterion The field/type pairs.
        #
        # @return [ Selectable ] The cloned selectable.
        def type_of(criterion)
          raise Errors::CriteriaArgumentRequired.new(:type_of) if criterion.nil?

          and_with_operator(criterion, '$type')
        end

        # Construct a text search selector.
        #
        # @example Construct a text search selector.
        #   selectable.text_search("testing")
        #
        # @example Construct a text search selector with options.
        #   selectable.text_search("testing", :$language => "fr")
        #
        # @note Per https://www.mongodb.com/docs/manual/reference/operator/query/text/
        #   it is not currently possible to supply multiple text search
        #   conditions in a query. ActiveDocument will build such a query but the
        #   server will return an error when trying to execute it.
        #
        # @param [ String | Symbol ] terms A string of terms that MongoDB parses
        #   and uses to query the text index.
        # @param [ Hash ] opts Text search options. See MongoDB documentation
        #   for options.
        #
        # @return [ Selectable ] The cloned selectable.
        def text_search(terms, opts = nil)
          raise Errors::CriteriaArgumentRequired.new(:terms) if terms.nil?

          clone.tap do |query|
            criterion = { '$text' => { '$search' => terms } }
            criterion['$text'].merge!(opts) if opts
            if query.selector['$text']
              # Per https://www.mongodb.com/docs/manual/reference/operator/query/text/
              # multiple $text expressions are not currently supported by
              # MongoDB server, but build the query correctly instead of
              # overwriting previous text search condition with the currently
              # given one.
              ActiveDocument.logger.warn('Multiple $text expressions per query are not currently supported by the server')
              query.selector = { '$and' => [query.selector] }.merge(criterion)
            else
              query.selector = query.selector.merge(criterion)
            end
          end
        end

        # This is the general entry point for most MongoDB queries. This either
        # creates a standard field: value selection, and expanded selection with
        # the use of hash methods, or a $where selection if a string is provided.
        #
        # @example Add a standard selection.
        #   selectable.where(name: "syd")
        #
        # @example Add a javascript selection.
        #   selectable.where("this.name == 'syd'")
        #
        # @param [ [ Hash | String ]... ] *criterion The standard selection
        #   or javascript string.
        #
        # @return [ Selectable ] The cloned selectable.
        def where(*criteria)
          selectable = clone

          criteria.each do |criterion|
            raise Errors::CriteriaArgumentRequired.new(:where) if criterion.nil?

            # We need to save the criterion in an instance variable so
            # Modifiable methods know how to create a polymorphic object.
            # Note that this method in principle accepts multiple criteria,
            # but only the first one will be stored in @criterion. This
            # works out to be fine because first_or_create etc. methods
            # only ever specify one criterion to #where.
            @criterion = criterion
            selectable = if criterion.is_a?(String)
                           js_query(criterion)
                         else
                           expr_query(criterion)
                         end
          end

          selectable.reset_state!
        end

        private

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
            # The prepare_for_merging method already takes the negation into account.
            # We set negating to false here so that ``and`` doesn't also apply
            # negation and we have a double negative.
            crit.negating = false
            crit = crit.and(field => val)
          end
          crit
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
        #   selectable.__combine_criteria__([ 1, 2 ], "$in")
        #
        # @param [ Array<Hash | ActiveDocument::Criteria> ] criteria Multiple key/value pair
        #   matches or Criteria objects.
        # @param [ String ] operator The MongoDB operator.
        #
        # @return [ Selectable ] The new selectable.
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

        # Prepare the value for merging.
        #
        # @api private
        #
        # @example Prepare the value.
        #   selectable.prepare_for_merging("field", "$gt", 10)
        #
        # @param [ String ] field The name of the field.
        # @param [ Object ] value The value.
        #
        # @return [ Object ] The serialized value.
        def prepare_for_merging(field, operator, value)
          # TODO: Skipped because these are type-casted
          unless /exists|type|size/.match?(operator)
            field = field.to_s
            name = aliases[field] || field
            serializer = serializers[name]
            value = serializer.evolve(value) if serializer
          end
          selection = { operator => value }
          negating? ? { '$not' => selection } : selection
        end

        # Adds the specified expression to the query.
        #
        # Criterion must be a hash in one of the following forms:
        # - { field_name: value }
        # - { 'field_name' => value }
        # - { key_instance: value }
        # - { '$operator' => operator_value_expression }
        #
        # Field name and operator may be given as either strings or symbols.
        #
        # @example Create the selection.
        #   selectable.expr_query(age: 50)
        #
        # @param [ Hash ] criterion The field/value pairs.
        #
        # @return [ Selectable ] The cloned selectable.
        # @api private
        def expr_query(criterion)
          if criterion.nil?
            raise ArgumentError.new('Criterion cannot be nil here')
          end

          unless criterion.is_a?(Hash)
            raise Errors::InvalidQuery.new("Expression must be a Hash: #{Errors::InvalidQuery.truncate_expr(criterion)}")
          end

          normalized = QueryNormalizer.normalize_expr(criterion, negating: negating?)
          clone.tap do |query|
            normalized.each do |field, value|
              field_s = field.to_s
              if field_s.start_with?('$')
                # Query expression-level operator, like $and or $where
                query.add_operator_expression(field_s, value)
              else
                query.add_field_expression(field, value)
              end
            end
            query.reset_state!
          end
        end

        # Create a javascript selection.
        #
        # @api private
        #
        # @example Create the javascript selection.
        #   selectable.js_query("this.age == 50")
        #
        # @param [ String ] criterion The javascript as a string.
        #
        # @return [ Selectable ] The cloned selectable
        def js_query(criterion)
          clone.tap do |query|
            if negating?
              query.add_operator_expression('$and',
                                            [{ '$nor' => [{ '$where' => criterion }] }])
            else
              query.add_operator_expression('$where', criterion)
            end
            query.reset_state!
          end
        end

        # Calling .flatten on an array which includes a Criteria instance
        # evaluates the criteria, which we do not want. Hence this method
        # explicitly only expands Array objects and Array subclasses.
        def flatten_args(array)
          out = []
          pending = array.dup
          until pending.empty?
            item = pending.shift
            if item.nil?
              # skip
            elsif item.is_a?(Array)
              pending.concat(item)
            else
              out << item
            end
          end
          out
        end

        class << self

          # Get the methods on the selectable that can be forwarded to from a model.
          #
          # @example Get the forwardable methods.
          #   Selectable.forwardables
          #
          # @return [ Array<Symbol> ] The names of the forwardable methods.
          def forwardables
            public_instance_methods(false) -
              %i[negating negating= negating? selector selector=]
          end
        end
      end
    end
  end
end
