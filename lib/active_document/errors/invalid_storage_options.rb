# frozen_string_literal: true

module ActiveDocument
  module Errors

    # Raised when options provided to :store_in are invalid.
    class InvalidStorageOptions < BaseError

      # Create the new error.
      #
      # @example Create the new error.
      #   InvalidStorageOptions.new(Person, invalid_option: 'name')
      #
      # @param [ Class ] klass The model class.
      # @param [ Hash | String | Symbol ] options The provided options.
      def initialize(klass, options)
        super(
          compose_message(
            'invalid_storage_options',
            { klass: klass, options: options }
          )
        )
      end
    end
  end
end
