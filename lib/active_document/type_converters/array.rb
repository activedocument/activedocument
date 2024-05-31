# frozen_string_literal: true

module ActiveDocument
  module TypeConverters
    # Adds type-casting behavior to Array class.
    module Array
      extend self

      def to_query(array)

      end

      # Convert the array into an array of object ids for use in queries.
      #
      # @example Evolve the array to object ids.
      #   to_query_object_id([id])
      #
      # @param [ Array ] array The array to convert.
      #
      # @return [ Array<BSON::ObjectId> ] The converted array.
      def to_query_object_id(array)
        array.map! { |element| ActiveDocument::TypeConverters::Object.to_database_object_id(element) }
        array.compact!
        array
      end

      def to_database_object_id(array)
        array.map! { |element| ActiveDocument::TypeConverters::Object.to_database_object_id(element) }
        array.compact!
        array
      end


      # Mongoize the array into an array of object ids.
      #
      # @example Evolve the array to object ids.
      #   [ id ].to_database_object_id
      #
      # @return [ Array<BSON::ObjectId> ] The converted array.
      def to_database_object_id
        map!(&:to_database_object_id).compact!
        self
      end

      # Converts the array for storing as a time.
      #
      # @note Returns a local time in the default time zone.
      #
      # @example Convert the array to a time.
      #   [ 2010, 1, 1 ].__mongoize_time__
      #   # => 2010-01-01 00:00:00 -0500
      #
      # @return [ Time | ActiveSupport::TimeWithZone ] Local time in the
      #   configured default time zone corresponding to date/time components
      #   in this array.
      def __mongoize_time__
        ::Time.zone.local(*self)
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ Array | nil ] The object or nil.
      def mongoize
        ::Array.mongoize(self)
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   Array.mongoize([ 1, 2, 3 ])
      #
      # @param [ Object ] object The object to mongoize.
      #
      # @return [ Array | nil ] The object mongoized or nil.
      def to_database_casted(object)
        return if object.nil?

        case object
        when ::Array, ::Set
          object.map(&:mongoize)
        end
      end
    end
  end
end

Array.include(ActiveDocument::Extensions::Array)
Array.extend(ActiveDocument::Extensions::Array::ClassMethods)
