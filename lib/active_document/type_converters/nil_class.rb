# frozen_string_literal: true

module ActiveDocument
  module Extensions
    # Adds type-casting behavior to NilClass.
    module NilClass

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
