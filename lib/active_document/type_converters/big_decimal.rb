# frozen_string_literal: true

module ActiveDocument
  module Extensions
    # Adds type-casting behavior to BigDecimal class.
    module BigDecimal

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ String | BSON::Decimal128 | nil ] The object or nil.
      def mongoize
        ::BigDecimal.mongoize(self)
      end

      module ClassMethods
        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @param [ Object ] object The object to demongoize.
        #
        # @return [ BigDecimal | nil ] A BigDecimal derived from the object or nil.
        def to_ruby_casted(object)
          return if object.blank?

          if object.is_a?(BSON::Decimal128)
            object.to_big_decimal
          elsif object.numeric?
            object.to_d
          end
        end

        # Convert an object of any type to an array to store in the db.
        #
        # @example Mongoize the object.
        #   BigDecimal.mongoize(123)
        #
        # @param [ Object ] object The object to Mongoize
        #
        # @return [ String | BSON::Decimal128 | nil ] A String or Decimal128
        #   representing the object or nil. String if ActiveDocument.map_big_decimal_to_decimal128
        #   is false, BSON::Decimal128 otherwise.
        def to_database_casted(object)
          return if object.blank?

          if ActiveDocument.map_big_decimal_to_decimal128
            if object.is_a?(BSON::Decimal128)
              object
            elsif object.is_a?(BigDecimal)
              BSON::Decimal128.new(object)
            elsif object.numeric?
              BSON::Decimal128.new(object.to_s)
            elsif !object.is_a?(String)
              object.try(:to_d)
            end
          elsif object.is_a?(BSON::Decimal128) || object.numeric?
            object.to_s
          elsif !object.is_a?(String)
            object.try(:to_d)&.to_s
          end
        end
      end
    end
  end
end

BigDecimal.include(ActiveDocument::Extensions::BigDecimal)
