# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module Queryable
      module Extensions

        # Adds query type-casting behavior to Object class.
        module Object

          # Deep copy the object. This is for API compatibility, but needs to be
          # overridden.
          #
          # @example Deep copy the object.
          #   1.__deep_copy__
          #
          # @return [ Object ] self.
          def __deep_copy__
            self
          end

          module ClassMethods

            # Evolve the object.
            #
            # @note This is here for API compatibility.
            #
            # @example Evolve an object.
            #   Object.evolve("test")
            #
            # @return [ Object ] The provided object.
            def evolve(object)
              object
            end

            private

            # Evolve the object.
            #
            # @api private
            #
            # @todo Durran refactor out case statement.
            #
            # @example Evolve an object and yield.
            #   Object.evolve("test") do |obj|
            #     obj.to_s
            #   end
            #
            # @return [ Object ] The evolved object.
            def __evolve__(object)
              return nil if object.nil?

              case object
              when ::Array
                object.map { |obj| evolve(obj) }
              when ::Range
                object.__evolve_range__
              else
                res = yield(object)
                res.nil? ? object : res
              end
            end
          end
        end
      end
    end
  end
end

Object.include ActiveDocument::Criteria::Queryable::Extensions::Object
Object.extend ActiveDocument::Criteria::Queryable::Extensions::Object::ClassMethods
