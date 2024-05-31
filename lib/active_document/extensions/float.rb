# frozen_string_literal: true

module ActiveDocument
  module Extensions

    # Adds type-casting behavior to Float class.
    module Float

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
          else
            object.try(:to_f)
          end
        end
        alias_method :demongoize, :mongoize
      end
    end
  end
end

Float.include ActiveDocument::Extensions::Float
Float.extend(ActiveDocument::Extensions::Float::ClassMethods)
