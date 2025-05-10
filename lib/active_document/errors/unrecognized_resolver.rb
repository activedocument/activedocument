# frozen_string_literal: true

module ActiveDocument
  module Errors
    # Raised when a model resolver is referenced, but not registered.
    #
    #   class Manager
    #     include ActiveDocument::Document
    #     belongs_to :unit, polymorphic: :org
    #   end
    #
    # If `:org` has not previously been registered as a model resolver,
    # ActiveDocument will raise UnrecognizedResolver when it tries to resolve
    # a manager's unit.
    class UnrecognizedResolver < ActiveDocumentError
      def initialize(resolver)
        super(
          compose_message(
            'unrecognized_resolver',
            resolver: resolver.inspect,
            resolvers: [ :default, *ActiveDocument::ModelResolver.resolvers.keys ].inspect
          )
        )
      end
    end
  end
end
