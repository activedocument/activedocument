# frozen_string_literal: true

module ActiveDocument
  module Errors

    # Raised when invalid arguments are passed to #find.
    class InvalidFind < ActiveDocumentError

      # Create the new invalid find error.
      #
      # @example Create the error.
      #   InvalidFind.new
      def initialize
        super(compose_message('calling_document_find_with_nil_is_invalid', {}))
      end
    end
  end
end
