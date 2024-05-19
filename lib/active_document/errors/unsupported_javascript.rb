# frozen_string_literal: true

module ActiveDocument
  module Errors

    # Raised when Javascript criteria selector is passed for embedded document.
    class UnsupportedJavascript < BaseError

      # Create the new error caused by using Javascript in embedded document criteria selector.
      #
      # @example Create the error.
      #   UnsupportedJavascriptSelector.new(Album, "this.name == '101'")
      #
      # @param [ Class ] klass The embedded document class.
      # @param [ String ] javascript The javascript expression.
      def initialize(klass, javascript)
        super(
          compose_message(
            'unsupported_javascript',
            { klass: klass, javascript: javascript }
          )
        )
      end
    end
  end
end
