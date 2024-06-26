# frozen_string_literal: true

module ActiveDocument
  module Errors

    # This error is raised when trying to reference an embedded document from
    # a document in another collection that is not its parent.
    #
    # @example An illegal reference to an embedded document.
    #   class Post
    #     include ActiveDocument::Document
    #     references_many :addresses
    #   end
    #
    #   class Address
    #     include ActiveDocument::Document
    #     embedded_in :person
    #     referenced_in :post
    #   end
    class MixedRelations < BaseError
      def initialize(root_klass, embedded_klass)
        super(
          compose_message(
            'mixed_relations',
            { root: root_klass, embedded: embedded_klass }
          )
        )
      end
    end
  end
end
