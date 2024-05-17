# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      class HasOne

        # The Builder behavior for has_one associations.
        module Buildable

          # This method either takes an _id or an object and queries for the
          # inverse side using the id or sets the object after clearing the
          # associated object.
          #
          # @param [ Object ] base The base object.
          # @param [ Object ] object The object to use to build the association.
          # @param [ String ] _type The type of the association.
          # @param [ nil ] _selected_fields Must be nil.
          #
          # @return [ ActiveDocument::Document ] A single document.
          def build(base, object, _type = nil, _selected_fields = nil)
            if query?(object)
              execute_query(object, base) unless base.new_record?
            else
              clear_associated(object)
              object
            end
          end

          private

          def clear_associated(object)
            unless inverse
              raise Errors::InverseNotFound.new(
                @owner_class,
                name,
                object.class,
                foreign_key
              )
            end

            return unless object && (associated = object.send(inverse))

            associated.substitute(nil)
          end

          def query_criteria(object, base)
            crit = klass.criteria
            crit = crit.apply_scope(scope)
            crit = crit.where(foreign_key => object)
            with_polymorphic_criterion(crit, base)
          end

          def execute_query(object, base)
            query_criteria(object, base).take
          end

          def with_polymorphic_criterion(criteria, base)
            if polymorphic?
              criteria.where(type => base.class.name)
            else
              criteria
            end
          end

          def query?(object)
            object && !object.is_a?(ActiveDocument::Document)
          end
        end
      end
    end
  end
end
