# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to Date class.
    module Date

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   date.mongoize
      #
      # @return [ Time ] The object mongoized.
      def mongoize
        ::Date.mongoize(self)
      end

      module ClassMethods

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Date.demongoize(object)
        #
        # @param [ Time ] object The time from Mongo.
        #
        # @return [ Date | nil ] The object as a date or nil.
        def demongoize(object)
          return if object.nil?

          if object.is_a?(String)
            object = TypeConverters::Time.cast(object)
            return object if object.is_a?(RawValue)
          end

          # TODO: RawValue
          return unless object.acts_like?(:time) || object.acts_like?(:date)

          ::Date.new(object.year, object.month, object.day)
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Date.mongoize("2012-1-1")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Time | nil ] The object mongoized or nil.
        def mongoize(object)
          return if object.blank?

          time = if object.is_a?(String)
                   begin
                     # https://jira.mongodb.org/browse/MONGOID-4460
                     ::Time.parse(object)
                   rescue ArgumentError => e # rubocop:disable Lint/UselessRescue
                     raise(e) # TODO: RawValue error
                   end
                 else
                   TypeConverters::Time.cast(object)
                 end

          raise ArgumentError.new if time.is_a?(ActiveDocument::RawValue)

          return unless time.acts_like?(:time)

          ::Time.utc(time.year, time.month, time.day)
        end
      end
    end
  end
end

Date.include ActiveDocument::Extensions::Date
Date.extend(ActiveDocument::Extensions::Date::ClassMethods)
