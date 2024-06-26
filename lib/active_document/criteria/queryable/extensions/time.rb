# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module Queryable
      module Extensions

        # Adds query type-casting behavior to Time class.
        module Time

          # Evolve the time as a date, UTC midnight.
          #
          # @example Evolve the time to a date query format.
          #   time.__evolve_date__
          #
          # @return [ Time ] The date at midnight UTC.
          def __evolve_date__
            ::Time.utc(year, month, day, 0, 0, 0, 0)
          end

          # Evolve the time into a utc time.
          #
          # @example Evolve the time.
          #   time.__evolve_time__
          #
          # @return [ Time ] The time in UTC.
          def __evolve_time__
            getutc
          end

          module ClassMethods

            # Evolve the object to an date.
            #
            # @example Evolve dates.
            #
            # @example Evolve string dates.
            #
            # @example Evolve date ranges.
            #
            # @param [ Object ] object The object to evolve.
            #
            # @return [ Time ] The evolved date time.
            def evolve(object)
              res = begin
                object.try(:__evolve_time__)
              rescue ArgumentError
                nil
              end
              res.nil? ? object : res
            end
          end
        end
      end
    end
  end
end

Time.include ActiveDocument::Criteria::Queryable::Extensions::Time
Time.extend ActiveDocument::Criteria::Queryable::Extensions::Time::ClassMethods
