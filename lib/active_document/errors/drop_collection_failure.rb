# frozen_string_literal: true

module ActiveDocument
  module Errors

    # Raised when an attempt to drop a collection failed.
    class DropCollectionFailure < ActiveDocumentError

      # Instantiate the drop collection error.
      #
      # @param [ String ] collection_name The name of the collection that
      #   ActiveDocument failed to drop.
      #
      # @api private
      def initialize(collection_name)
        super(
          compose_message(
            'drop_collection_failure',
            {
              collection_name: collection_name
            }
          )
        )
      end
    end
  end
end
