# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to BSON::Binary class.
    module Binary

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ BSON::Binary | nil ] The object.
      def mongoize
        BSON::Binary.mongoize(self)
      end

      module ClassMethods

        # Mongoize an object of any type to how it's stored in the db.
        #
        # @example Mongoize the object.
        #   BigDecimal.mongoize(123)
        #
        # @param [ Object ] object The object to Mongoize
        #
        # @return [ BSON::Binary | nil ] A Binary representing the object or nil.
        def mongoize(object)
          return if object.nil?

          case object
          when BSON::Binary then object
          when String, Symbol then BSON::Binary.new(object.to_s)
          else ActiveDocument::RawValue(object, 'BSON::Binary')
          end
        end
        alias_method :demongoize, :mongoize
      end
    end
  end
end

BSON::Binary.include ActiveDocument::Extensions::Binary
BSON::Binary.extend(ActiveDocument::Extensions::Binary::ClassMethods)
