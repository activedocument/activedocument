# frozen_string_literal: true

module ActiveDocument
  module Errors

    # This error is raised when a default client is not defined.
    class NoDefaultClient < ActiveDocumentError

      # Create the new error with the defined client names.
      #
      # @example Create the new error.
      #   NoDefaultClient.new([ :analytics ])
      #
      # @param [ Array<Symbol> ] keys The defined clients.
      def initialize(keys)
        super(
          compose_message('no_default_client', { keys: keys.join(', ') })
        )
      end
    end
  end
end
