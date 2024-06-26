# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module Queryable

      # Provides a DSL around crafting aggregation framework commands.
      module Aggregable

        # @attribute [r] pipeline The aggregation pipeline.
        attr_reader :pipeline

        # @attribute [rw] aggregating Flag for whether or not we are aggregating.
        attr_writer :aggregating

        # Has the aggregable enter an aggregation state. Ie, are only aggregation
        # operations allowed at this point on.
        #
        # @example Is the aggregable aggregating?
        #   aggregable.aggregating?
        #
        # @return [ true | false ] If the aggregable is aggregating.
        def aggregating?
          !!@aggregating
        end

        # Add a group ($group) operation to the aggregation pipeline.
        #
        # @example Add a group operation being verbose.
        #   aggregable.group(count: { "$sum" => 1 }, max: { "$max" => "likes" })
        #
        # @example Add a group operation using symbol shortcuts.
        #   aggregable.group(count: { '$sum' => 1 }, max: { '$max' => 'likes' })
        #
        # @param [ Hash ] operation The group operation.
        #
        # @return [ Aggregable ] The aggregable.
        def group(operation)
          aggregation(operation) do |pipeline|
            pipeline.group(operation)
          end
        end

        # Add a projection ($project) to the aggregation pipeline.
        #
        # @example Add a projection to the pipeline.
        #   aggregable.project(author: 1, name: 0)
        #
        # @param [ Hash ] operation The projection to make.
        #
        # @return [ Aggregable ] The aggregable.
        def project(operation = nil)
          aggregation(operation) do |pipeline|
            pipeline.project(operation)
          end
        end

        # Add an unwind ($unwind) to the aggregation pipeline.
        #
        # @example Add an unwind to the pipeline.
        #   aggregable.unwind(:field)
        #
        # @param [ String | Symbol ] field The name of the field to unwind.
        #
        # @return [ Aggregable ] The aggregable.
        def unwind(field)
          aggregation(field) do |pipeline|
            pipeline.unwind(field)
          end
        end

        private

        # Add the aggregation operation.
        #
        # @api private
        #
        # @example Aggregate on the operation.
        #   aggregation(operation) do |pipeline|
        #     pipeline.push("$project" => operation)
        #   end
        #
        # @param [ Hash ] operation The operation for the pipeline.
        #
        # @return [ Aggregable ] The cloned aggregable.
        def aggregation(operation)
          return self unless operation

          clone.tap do |query|
            unless aggregating?
              query.pipeline.concat(query.selector.to_pipeline)
              query.pipeline.concat(query.options.to_pipeline)
              query.aggregating = true
            end
            yield(query.pipeline)
          end
        end
      end
    end
  end
end
