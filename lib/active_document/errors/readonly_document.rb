# frozen_string_literal: true

module ActiveDocument
  module Errors

    # Raised when attempting to persist a document that was loaded from the
    # database with partial fields.
    class ReadonlyDocument < BaseError

      # Instantiate the exception.
      #
      # @example Create the error.
      #   ReadonlyDocument.new(Band)
      #
      # @param [ Class ] klass The document class.
      def initialize(klass)
        super(compose_message('readonly_document', { klass: klass }))
      end
    end
  end
end
