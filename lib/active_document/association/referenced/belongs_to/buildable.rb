# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      class BelongsTo

        # The Builder behavior for belongs_to associations.
        module Buildable

          # This method either takes an _id or an object and queries for the
          # inverse side using the id or sets the object.
          #
          # @example Build the document.
          #   relation.build(meta, attrs)
          #
          # @param [ Object ] _base The base object.
          # @param [ Object ] object The object to use to build the association.
          # @param [ String ] type The type of the association.
          # @param [ nil ] _selected_fields Must be nil.
          #
          # @return [ ActiveDocument::Document ] A single document.
          def build(_base, object, type = nil, _selected_fields = nil)
            return object unless query?(object)

            execute_query(object, type)
          end

          private

          def execute_query(object, type)
            query_criteria(object, type).take
          end

          def query_criteria(object, type)
            cls = type ? type.constantize : relation_class
            crit = cls.criteria
            crit = crit.apply_scope(scope)
            crit.where(primary_key => object)
          end

          def query?(object)
            object && !object.is_a?(ActiveDocument::Document)
          end
        end
      end
    end
  end
end
