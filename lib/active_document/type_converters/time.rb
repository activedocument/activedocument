# frozen_string_literal: true

module ActiveDocument
  module TypeConverters

    # Type-casting behavior for Time class.
    module Time
      extend self

      # Prepare a Time object to store in the database.
      #
      # @example Prepare a Time object to store in database.
      #   TypeConverters::Time.to_database(time)
      #
      # @return [ Time | nil ] The prepared Time object or nil.
      def to_database(time)
        return unless time

        ::Time.at(time.to_i, time.subsec * 1_000_000).utc
      end

      # Prepare any object to store in the database as a time field.
      #
      # @example Cast the object to store in database.
      #   TypeConverters::Time.to_database_cast("2012-1-1")
      #
      # @param [ Object ] object The object to cast.
      #
      # @return [ Time | nil ] The cast object or nil.
      def to_database_cast(object)
        time = cast(object)

        return unless time

        # TODO: Handle this generically
        raise ArgumentError if time.is_a?(ActiveDocument::RawValue)

        to_database(time.utc)
      end

      def to_query_cast(object)
        time = cast(object)
        time = to_database(time.utc) if time.is_a?(::Time)
        time
      end

      # Convert the object from its mongo friendly ruby type to this type.
      #
      # @example Demongoize the object.
      #   Time.demongoize(object)
      #
      # @param [ Time ] object The time from Mongo.
      #
      # @return [ Time | nil ] The object as a time.
      def to_ruby_cast(object)
        time = cast(object)
        time = time.in_time_zone if time.is_a?(::Time)
        time
      end

      # Returns a local time in the current time zone,
      # unless the object is a Time-like value it a zone or offset
      # already specified.
      # Mongoize the string for storage.
      # Neutral about time zone
      #
      # @note Returns a local time in the default time zone.
      #
      # @example Mongoize the string.
      #   cast_from_string("2012-01-01")
      #   # => 2012-01-01 00:00:00 -0500
      #
      # @raise [ ArgumentError ] The string is not a valid time string.
      #
      # @return [ Time | ActiveSupport::TimeWithZone ] Local time in the
      #   configured default time zone corresponding to this string.
      # TODO: make private
      def cast(object)
        return if object.blank?

        # TODO: Handle this generically
        object = object.raw_value if object.is_a?(ActiveDocument::RawValue)

        case object
        when ::Time, ActiveSupport::TimeWithZone
          object
        when DateTime
          object.to_time
        when Date
          cast_from_date(object)
        when ::Array
          cast_from_array(object)
        when String
          cast_from_string(object)
        when Integer, Float, BigDecimal
          ::Time.zone.at(object)
        when BSON::Timestamp
          ::Time.zone.at(object.seconds)
        end
      rescue ArgumentError
        ActiveDocument::RawValue(object)
      end

      private

      # Mongoize the string for storage.
      #
      # @note Returns a local time in the default time zone.
      #
      # @example Mongoize the string.
      #   cast_from_string("2012-01-01")
      #   # => 2012-01-01 00:00:00 -0500
      #
      # @raise [ ArgumentError ] The string is not a valid time string.
      #
      # @return [ Time | ActiveSupport::TimeWithZone ] Local time in the
      #   configured default time zone corresponding to this string.
      def cast_from_string(string)
        # This extra Time.parse is required to raise an error if the string
        # is not a valid time string. ActiveSupport::TimeZone does not
        # perform this check.
        ::Time.parse(string) # rubocop:disable Rails/TimeZone
        ::Time.zone.parse(string)
      end

      # Converts the array for storing as a time.
      #
      # @note Returns a local time in the default time zone.
      #
      # @example Convert the array to a time.
      #   cast_from_array([2010, 1, 1])
      #   # => 2010-01-01 00:00:00 -0500
      #
      # @return [ Time | ActiveSupport::TimeWithZone ] Local time in the
      #   configured default time zone corresponding to date/time components
      #   in this array.
      def cast_from_array(array)
        ::Time.zone.local(*array)
      end

      # Convert the date into a time.
      #
      # @example Convert the date to a time.
      #   cast_from_date(Date.new(2018, 11, 1))
      #   # => Thu, 01 Nov 2018 00:00:00 EDT -04:00
      #
      # @return [ Time | ActiveSupport::TimeWithZone ] Local time in the
      #   configured default time zone corresponding to local midnight of
      #   this date.
      def cast_from_date(date)
        ::Time.zone.local(date.year, date.month, date.day)
      end
    end
  end
end
