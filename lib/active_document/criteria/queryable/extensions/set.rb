# frozen_string_literal: true

require 'set'

module ActiveDocument
  class Criteria
    module Queryable
      module Extensions

        # Adds query type-casting behavior to Set class.
        module Set
          module ClassMethods

            # Evolve the set, casting all its elements.
            #
            # @example Evolve the set.
            #   Set.evolve(set)
            #
            # @param [ Set | Object ] object The object to evolve.
            #
            # @return [ Array ] The evolved set.
            def evolve(object)
              return object if !object || !object.respond_to?(:map)

              object.map { |obj| obj.class.evolve(obj) }
            end
          end
        end
      end
    end
  end
end

Set.extend ActiveDocument::Criteria::Queryable::Extensions::Set::ClassMethods
