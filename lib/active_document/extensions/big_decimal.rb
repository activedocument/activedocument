# frozen_string_literal: true

module ActiveDocument
  module Extensions
    # Adds type-casting behavior to BigDecimal class.
    module BigDecimal
      # Behavior to be invoked when the module is included.
      #
      # @param [ Module ] base the class or module doing the including
      #
      # @api private
      def self.included(base)
        base.extend(ClassMethods)
      end

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

      # Is the BigDecimal a number?
      #
      # @example Is the object a number?.
      #   object.numeric?
      #
      # @return [ true ] Always true.
      def numeric?
        true
      end

      module ClassMethods
        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @param [ Object ] object The object to demongoize.
        #
        # @return [ BigDecimal | nil ] A BigDecimal derived from the object or nil.
        def demongoize(object)
          return if object.blank?

          if object.is_a?(BSON::Decimal128)
            object.to_big_decimal
          elsif object.numeric?
            object.to_d
          end
        end

        # Mongoize an object of any type to how it's stored in the db.
        #
        # @example Mongoize the object.
        #   BigDecimal.mongoize(123)
        #
        # @param [ Object ] object The object to Mongoize
        #
        # @return [ String | BSON::Decimal128 | nil ] A String or Decimal128
        #   representing the object or nil. String if ActiveDocument.map_big_decimal_to_decimal128
        #   is false, BSON::Decimal128 otherwise.
        def mongoize(object)
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
