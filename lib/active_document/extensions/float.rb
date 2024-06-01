# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to Float class.
    module Float

      # Converts the float into a time as the number of seconds since the epoch.
      #
      # @example Convert the float into a time.
      #   1335532685.117847.__mongoize_time__
      #
      # @return [ Time | ActiveSupport::TimeWithZone ] The time.
      def __mongoize_time__
        ::Time.zone.at(self)
      end

      # Is the float a number?
      #
      # @example Is the object a number?.
      #   object.numeric?
      #
      # @return [ true ] Always true.
      def numeric?
        true
      end

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Float.mongoize("123.11")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Float | nil ] The object mongoized or nil.
        def mongoize(object)
          return if object.blank?

          if object.is_a?(String)
            object.to_f if object.numeric?
          elsif object.respond_to?(:to_f)
            object.to_f
          else
            ActiveDocument::RawValue(object, 'Float')
          end
        end
        alias_method :demongoize, :mongoize
      end
    end
  end
end

Float.include ActiveDocument::Extensions::Float
Float.extend(ActiveDocument::Extensions::Float::ClassMethods)
