# frozen_string_literal: true

module ActiveDocument
  module Errors
    # This error is raised when an around callback is
    # defined by the user without a yield
    class InvalidAroundCallback < ActiveDocumentError
      # Create the new error.
      #
      # @api private
      def initialize
        super(compose_message('invalid_around_callback'))
      end
    end
  end
end
