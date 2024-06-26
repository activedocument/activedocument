# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to Time class.
    module DateTime

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   date_time.mongoize
      #
      # @return [ Time ] The object mongoized.
      def mongoize
        ::DateTime.mongoize(self)
      end

      module ClassMethods

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   DateTime.demongoize(object)
        #
        # @param [ Time ] object The time from Mongo.
        #
        # @return [ DateTime | nil ] The object as a datetime or nil.
        def demongoize(object)
          ::Time.demongoize(object).try(:to_datetime)
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   DateTime.mongoize("2012-1-1")
        #
        # @param [ Object ] object The object to convert.
        #
        # @return [ Time ] The object mongoized.
        def mongoize(object)
          ::Time.mongoize(object)
        end
      end
    end
  end
end

DateTime.include ActiveDocument::Extensions::DateTime
DateTime.extend(ActiveDocument::Extensions::DateTime::ClassMethods)
