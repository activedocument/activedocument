# frozen_string_literal: true

module ActiveDocument
  module Errors

    # This error is raised when no clients exists in the database
    # configuration.
    class NoClientsConfig < BaseError

      # Create the new error.
      #
      # @example Create the error.
      #   NoClientsConfig.new
      def initialize
        super(compose_message('no_clients_config', {}))
      end
    end
  end
end
