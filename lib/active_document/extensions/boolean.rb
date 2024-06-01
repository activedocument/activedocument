# frozen_string_literal: true

module ActiveDocument

  # Adds type-casting behavior to ActiveDocument::Boolean class.
  class Boolean
    TRUTHY_VALUES = /\A(true|t|yes|y|on|1|1.0)\z/i.freeze
    FALSY_VALUES = /\A(false|f|no|n|off|0|0.0)\z/i.freeze

    class << self

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   Boolean.mongoize("123.11")
      #
      # @return [ true | false | nil ] The object mongoized or nil.
      def mongoize(object)
        return if object.nil?

        if object.to_s&.match?(TRUTHY_VALUES)
          true
        elsif object.to_s&.match?(FALSY_VALUES)
          false
        else
          ActiveDocument::RawValue(object, 'Boolean')
        end
      end
      alias_method :demongoize, :mongoize
    end
  end
end
