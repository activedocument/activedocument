# frozen_string_literal: true

module ActiveDocument
  module Errors

    # This error is raised when an empty configuration file is attempted to be
    # loaded.
    class EmptyConfigFile < BaseError

      # Create the new error.
      #
      # @param [ String ] path The path of the config file used.
      #
      # @api private
      def initialize(path)
        super(
          compose_message(
            'empty_config_file',
            { path: path }
          )
        )
      end
    end
  end
end
