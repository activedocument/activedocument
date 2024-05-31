# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to Time class.
    module Time

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   time.mongoize
      #
      # @return [ Time | nil ] The object mongoized or nil.
      def mongoize
        TypeConverters::Time.to_database(self)
      end

      module ClassMethods

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Time.demongoize(object)
        #
        # @param [ Time ] object The time from Mongo.
        #
        # @return [ Time | nil ] The object as a time.
        def demongoize(object)
          TypeConverters::Time.to_ruby_cast(object)
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Time.mongoize("2012-1-1")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Time | nil ] The object mongoized or nil.
        def mongoize(object)
          TypeConverters::Time.to_database_cast(object)
        end
      end
    end
  end
end

Time.include ActiveDocument::Extensions::Time
Time.extend(ActiveDocument::Extensions::Time::ClassMethods)
