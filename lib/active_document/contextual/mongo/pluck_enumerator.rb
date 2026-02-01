# frozen_string_literal: true

require 'active_document/pluckable'

module ActiveDocument
  module Contextual
    class Mongo

      # Utility class to add enumerable behavior for Criteria#pluck_each.
      #
      # @api private
      class PluckEnumerator
        include Enumerable
        include Pluckable

        # Create the new PluckEnumerator.
        #
        # @api private
        #
        # @example Initialize a PluckEnumerator.
        #   PluckEnumerator.new(klass, view, fields)
        #
        # @param [ Class ] klass The base of the binding.
        # @param [ Mongo::Collection::View ] view The Mongo view context.
        # @param [ String | Symbol ] *fields Field(s) to pluck,
        #   which may include nested fields using dot-notation.
        def initialize(klass, view, fields)
          @klass = klass
          @view = view
          @fields = fields
        end

        # Iterate through plucked field value(s) from the database
        # for the view context. Yields result values progressively as
        # they are read from the database. The yielded results are
        # normalized according to their ActiveDocument field types.
        #
        # @api private
        #
        # @example Iterate through the plucked values from the database.
        #   context.pluck_each(:name) { |name| puts name }
        #
        # @param [ Proc ] &block The block to call once for each plucked
        #   result.
        #
        # @return [ Enumerator | PluckEnumerator ] The enumerator, or
        #   self if a block was given.
        def each(&block)
          return to_enum unless block

          prep = prepare_pluck(@fields, prepare_projection: true)
          @view.projection(prep[:projection]).each do |doc|
            yield_result(doc, prep[:field_names], &block)
          end

          self
        end

        private

        attr_reader :klass

        def yield_result(doc, field_names)
          values = field_names.map { |name| extract_value(doc, name, @klass) }
          yield(values.size == 1 ? values.first : values)
        end
      end
    end
  end
end
