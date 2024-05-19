# frozen_string_literal: true

module ActiveDocument
  module Extensions
    # Adds type-casting behavior to TrueClass
    module TrueClass
      # Get the value of the object as a mongo friendly sort value.
      #
      # @example Get the object as sort criteria.
      #   object.__sortable__
      #
      # @return [ Integer ] 1.
      # @deprecated
      def __sortable__
        1
      end
      ActiveDocument.deprecate(self, :__sortable__)

      # Is the passed value a boolean?
      #
      # @example Is the value a boolean type?
      #   true.is_a?(Boolean)
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

TrueClass.include ActiveDocument::Extensions::TrueClass
