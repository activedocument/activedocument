# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module Queryable
      module Extensions

        # Adds query type-casting behavior to Symbol class.
        module Symbol

          module ClassMethods

            # Evolves the symbol into a MongoDB friendly value - in this case
            # a symbol.
            #
            # @example Evolve the symbol
            #   Symbol.evolve("test")
            #
            # @param [ Object ] object The object to convert.
            #
            # @return [ Symbol ] The value as a symbol.
            def evolve(object)
              __evolve__(object) do |obj|
                obj.try(:to_sym)
              end
            end
          end
        end
      end
    end
  end
end

Symbol.include ActiveDocument::Criteria::Queryable::Extensions::Symbol
Symbol.extend ActiveDocument::Criteria::Queryable::Extensions::Symbol::ClassMethods
