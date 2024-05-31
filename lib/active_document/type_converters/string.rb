# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to String class.
    module String

      # Evolve the string into an object id if possible.
      #
      # @example Evolve the string.
      #   "test".to_query_object_id
      #
      # @return [ String | BSON::ObjectId ] The evolved string.
      def to_query_object_id
        convert_to_object_id
      end

      # Mongoize the string into an object id if possible.
      #
      # @example Evolve the string.
      #   "test".to_database_object_id
      #
      # @return [ String | BSON::ObjectId | nil ] The mongoized string.
      def to_database_object_id
        convert_to_object_id if present?
      end

      # Mongoize the string for storage.
      #
      # @note Returns a local time in the default time zone.
      #
      # @example Mongoize the string.
      #   "2012-01-01".__mongoize_time__
      #   # => 2012-01-01 00:00:00 -0500
      #
      # @raise [ ArgumentError ] The string is not a valid time string.
      #
      # @return [ Time | ActiveSupport::TimeWithZone ] Local time in the
      #   configured default time zone corresponding to this string.
      def __mongoize_time__
      end

      private

      # If the string is a legal object id, convert it.
      #
      # @api private
      #
      # @example Convert to the object id.
      #   string.convert_to_object_id
      #
      # @return [ String | BSON::ObjectId ] The string or the id.
      def convert_to_object_id
        BSON::ObjectId.legal?(self) ? BSON::ObjectId.from_string(self) : self
      end

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   String.mongoize("123.11")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ String ] The object mongoized.
        def to_database_casted(object)
          object.try(:to_s)
        end
        alias_method :demongoize, :mongoize
      end
    end
  end
end

String.include ActiveDocument::Extensions::String
String.extend(ActiveDocument::Extensions::String::ClassMethods)
