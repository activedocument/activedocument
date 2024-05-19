# frozen_string_literal: true

module ActiveDocument
  module Errors

    # This error is raised when a transaction is attempted to be used with a model whose client cannot use it since
    # the mongodb deployment doesn't support transactions.
    class TransactionsNotSupported < BaseError

      # Create the error.
      def initialize
        super('transactions_not_supported')
      end
    end
  end
end
