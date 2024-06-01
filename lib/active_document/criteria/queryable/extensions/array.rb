# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module Queryable
      module Extensions

        # Adds query type-casting behavior to Array class.
        module Array

          # Makes a deep copy of the array, deep copying every element inside the
          # array.
          #
          # @example Get a deep copy of the array.
          #   [ 1, 2, 3 ].__deep_copy__
          #
          # @return [ Array ] The deep copy of the array.
          def __deep_copy__
            map(&:__deep_copy__)
          end

          # Evolve the array into an array of mongo friendly dates. (Times at
          # midnight).
          #
          # @example Evolve the array to dates.
          #   [ Date.new(2010, 1, 1) ].__evolve_date__
          #
          # @return [ Array<Time> ] The array as times at midnight UTC.
          def __evolve_date__
            map(&:__evolve_date__)
          end

          # Evolve the array to an array of times.
          #
          # @example Evolve the array to times.
          #   [ 1231231231 ].__evolve_time__
          #
          # @return [ Array<Time> ] The array as times.
          def __evolve_time__
            map(&:__evolve_time__)
          end

          # Gets the array as options in the proper format to pass as MongoDB sort
          # criteria.
          #
          # @example Get the array as sorting options.
          #   [ :field, 1 ].__sort_option__
          #
          # @return [ Hash ] The array as sort criterion.
          def __sort_option__
            multi.each_with_object({}) do |criteria, options|
              options.merge!(criteria.__sort_pair__)
            end
          end

          # Get the array as a sort pair.
          #
          # @example Get the array as field/direction pair.
          #   [ field, 1 ].__sort_pair__
          #
          # @return [ Hash ] The field/direction pair.
          def __sort_pair__
            { first => ActiveDocument::Criteria::Translator.to_direction(last) }
          end

          private

          # Converts the array to a multi-dimensional array.
          #
          # @api private
          #
          # @example Convert to multi-dimensional.
          #   [ 1, 2, 3 ].multi
          #
          # @return [ Array ] The multi-dimensional array.
          def multi
            first.is_a?(::Symbol) || first.is_a?(::String) ? [self] : self
          end

          module ClassMethods

            # Evolve the object when the serializer is defined as an array.
            #
            # @example Evolve the object.
            #   Array.evolve(1)
            #
            # @param [ Object ] object The object to evolve.
            #
            # @return [ Object ] The evolved object.
            def evolve(object)
              case object
              when ::Array, ::Set
                object.map { |obj| obj.class.evolve(obj) }
              else
                ActiveDocument::RawValue(object, 'Array')
              end
            end
          end
        end
      end
    end
  end
end

Array.include ActiveDocument::Criteria::Queryable::Extensions::Array
Array.extend ActiveDocument::Criteria::Queryable::Extensions::Array::ClassMethods
