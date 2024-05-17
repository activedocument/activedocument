# frozen_string_literal: true

module ActiveDocument
  module Errors

    # This error is raised when trying to set a value in ActiveDocument that is not
    # already set with dynamic attributes or the field is not defined.
    class UnknownAttribute < BaseError

      # Create the new error.
      #
      # @example Instantiate the error.
      #   UnknownAttribute.new(Person, "gender")
      #
      # @param [ Class ] klass The model class.
      # @param [ String | Symbol ] name The name of the attribute.
      def initialize(klass, name)
        super(
          compose_message('unknown_attribute', { klass: klass.name, name: name })
        )
      end
    end
  end
end
