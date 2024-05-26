# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module Queryable
      module Extensions

        # Adds query type-casting behavior to NilClass.
        module NilClass

          # Evolve the nil into a date or time.
          #
          # @example Evolve the nil.
          #   nil.__evolve_time__
          #
          # @return [ nil ] nil.
          def __evolve_time__
            self
          end
          alias_method :__evolve_date__, :__evolve_time__
        end
      end
    end
  end
end

NilClass.include ActiveDocument::Criteria::Queryable::Extensions::NilClass
