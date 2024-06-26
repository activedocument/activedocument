# frozen_string_literal: true

module ActiveDocument
  module Errors

    # This error is raised when a transaction failed because
    # of an unexpected error.
    class TransactionError < BaseError

      # Creates the exception.
      #
      # @param [ StandardError ] error Error that caused the
      #   transaction failure.
      def initialize(error)
        super(
          compose_message(
            'transaction_error',
            { error: "#{error.class}: #{error.message}" }
          )
        )
      end
    end
  end
end
