# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to Time class.
    module Time

      # Mongoizes a Time into a time.
      #
      # Time always mongoize into Time instances
      # (which are themselves).
      #
      # @return [ Time ] self.
      def __mongoize_time__
        self
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   time.mongoize
      #
      # @return [ Time | nil ] The object mongoized or nil.
      def mongoize
        ::Time.mongoize(self)
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
        def to_ruby_casted(object, in_zone: true)
          return if object.blank?

          begin
            object = case object
                     when Time
                       object
                     when DateTime
                       object.to_time
                     when Date
                       ::Time.zone.local(object.year, object.month, object.day)
                     when ::Array
                       ::Time.zone.local(*object)
                     when String
                       # This extra Time.parse is required to raise an error if the string
                       # is not a valid time string. ActiveSupport::TimeZone does not
                       # perform this check.
                       ::Time.parse(object)
                       ::Time.zone.parse(object)
                     when Integer, Float, BigDecimal
                       ::Time.zone.at(object)
                     when BSON::Timestamp
                       ::Time.at(object.seconds)
                     end
          rescue ArgumentError
            return
          end

          return unless object

          in_zone ? object.in_time_zone(ActiveDocument.time_zone) : object
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
        def to_database_casted(object)
          time = to_ruby_casted(object, in_zone: false)
          ::Time.at(time.to_i, time.usec).utc
        end
      end
    end
  end
end
