# frozen_string_literal: true

module ActiveDocument
  module Extensions
    # Adds type-casting behavior to NilClass.
    module NilClass
      # Try to form a setter from this object.
      #
      # @example Try to form a setter.
      #   object.__setter__
      #
      # @return [ nil ] Always nil.
      # @deprecated
      def __setter__
        self
      end
      ActiveDocument.deprecate(self, :__setter__)

      # Get the name of a nil collection.
      #
      # @example Get the nil name.
      #   nil.collectionize
      #
      # @return [ String ] A blank string.
      def collectionize
        to_s.collectionize
      end
    end
  end
end

NilClass.include ActiveDocument::Extensions::NilClass
