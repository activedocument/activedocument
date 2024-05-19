# frozen_string_literal: true

module ActiveDocument
  module Errors

    # Raised when an attempt to create a collection failed.
    class CreateCollectionFailure < ActiveDocumentError

      # Instantiate the create collection error.
      #
      # @param [ String ] collection_name The name of the collection that
      #   ActiveDocument failed to create.
      # @param [ Hash ] collection_options The options that were used when
      #   tried to create the collection.
      # @param [ Mongo::Error::OperationFailure ] error The error raised when
      #   tried to create the collection.
      #
      # @api private
      def initialize(collection_name, collection_options, error)
        super(
          compose_message(
            'create_collection_failure',
            {
              collection_name: collection_name,
              collection_options: collection_options,
              error: "#{error.class}: #{error.message}"
            }
          )
        )
      end
    end
  end
end
