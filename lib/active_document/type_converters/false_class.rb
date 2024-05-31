# frozen_string_literal: true

module ActiveDocument
  module Extensions
    # Adds type-casting behavior to FalseClass.
    module FalseClass

      # Is the passed value a boolean?
      #
      # @example Is the value a boolean type?
      #   false.is_a?(Boolean)
      #
      # @param [ Class ] other The class to check.
      #
      # @return [ true | false ] If the other is a boolean.
      def is_a?(other)
        return true if other == ActiveDocument::Boolean || other.instance_of?(ActiveDocument::Boolean)

        super(other)
      end
    end
  end
end

FalseClass.include ActiveDocument::Extensions::FalseClass
