# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module Queryable
      module Extensions

        # Adds query type-casting behavior to Hash class.
        module Hash

          # Make a deep copy of this hash.
          #
          # @example Make a deep copy of the hash.
          #   { field: value }.__deep_copy__
          #
          # @return [ Hash ] The copied hash.
          def __deep_copy__
            {}.tap do |copy|
              each_pair do |key, value|
                copy.store(key, value.__deep_copy__)
              end
            end
          end

          # Get the hash as a sort option.
          #
          # @example Get the hash as a sort option.
          #   { field: 1 }.__sort_option__
          #
          # @return [ Hash ] The hash as sort option.
          def __sort_option__
            tap do |hash|
              hash.each_pair do |key, value|
                hash.store(key, ActiveDocument::Criteria::Translator.to_direction(value))
              end
            end
          end
        end
      end
    end
  end
end

Hash.include ActiveDocument::Criteria::Queryable::Extensions::Hash
