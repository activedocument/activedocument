# frozen_string_literal: true

module ActiveDocument
  module Errors

    # Raised when attempting to destroy a document that had destroy callbacks
    # return false.
    class DocumentNotDestroyed < BaseError

      # Instantiate the exception.
      #
      # @example Create the error.
      #   DocumentNotDestroyed.new(Band)
      #
      # @param [ Object ] id The document id.
      # @param [ Class ] klass The document class.
      def initialize(id, klass)
        super(compose_message('document_not_destroyed', { id: id.inspect, klass: klass }))
      end
    end
  end
end
