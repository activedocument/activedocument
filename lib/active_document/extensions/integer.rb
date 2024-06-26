# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to Integer class.
    module Integer

      # Is the integer a number?
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
        #   BigDecimal.mongoize("123.11")
        #
        # @return [ Integer | nil ] The object mongoized or nil.
        def mongoize(object)
          return if object.blank?

          if object.is_a?(String)
            object.to_i if object.numeric?
          else
            object.try(:to_i)
          end
        end
        alias_method :demongoize, :mongoize
      end
    end
  end
end

Integer.include ActiveDocument::Extensions::Integer
Integer.extend(ActiveDocument::Extensions::Integer::ClassMethods)
