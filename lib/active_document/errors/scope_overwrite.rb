# frozen_string_literal: true

module ActiveDocument
  module Errors

    # This error is raised when trying to create a scope with an name already
    # taken by another scope or method
    #
    # @example Create the error.
    #   ScopeOverwrite.new(Person,'teenies')
    class ScopeOverwrite < BaseError
      def initialize(model_name, scope_name)
        super(
          compose_message(
            'scope_overwrite',
            { model_name: model_name, scope_name: scope_name }
          )
        )
      end
    end
  end
end
