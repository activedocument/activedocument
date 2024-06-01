# frozen_string_literal: true

module ActiveDocument
  class Criteria
    module Queryable
      module Extensions

        # Adds query type-casting behavior to DateTime class.
        module DateTime

          # Evolve the date time into a mongo friendly UTC time.
          #
          # @example Evolve the date time.
          #   date_time.__evolve_time__
          #
          # @return [ Time ] The converted time in UTC.
          def __evolve_time__
            usec = strftime('%6N').to_f
            u = utc
            ::Time.utc(u.year, u.month, u.day, u.hour, u.min, u.sec, usec)
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
              rescue ArgumentError => e
                return ActiveDocument::RawValue(object, 'DateTime', e)
              end
              res.nil? ? ActiveDocument::RawValue(object, 'DateTime') : res
            end
          end
        end
      end
    end
  end
end

DateTime.include ActiveDocument::Criteria::Queryable::Extensions::DateTime
DateTime.extend ActiveDocument::Criteria::Queryable::Extensions::DateTime::ClassMethods
