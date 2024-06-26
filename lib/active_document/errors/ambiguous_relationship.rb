# frozen_string_literal: true

module ActiveDocument
  module Errors

    # This error is raised in case of an ambiguous association.
    #
    # @example An ambiguous association.
    #   class Person
    #     include ActiveDocument::Document
    #
    #     has_many :invitations, inverse_of: :person
    #     has_many :referred_invitations, class_name: "Invitation", inverse_of: :referred_by
    #   end
    #
    #   class Invitation
    #     include ActiveDocument::Document
    #
    #     belongs_to :person
    #     belongs_to :referred_by, class_name: "Person"
    #   end
    class AmbiguousRelationship < BaseError

      # Create the new error.
      #
      # @example Create the error.
      #   AmbiguousRelationship.new(
      #     Person, Drug, :person, [ :drugs, :evil_drugs ]
      #   )
      #
      # @param [ Class ] klass The base class.
      # @param [ Class ] inverse The inverse class.
      # @param [ Symbol ] name The relation name.
      # @param [ Array<Symbol> ] candidates The potential inverses.
      def initialize(klass, inverse, name, candidates)
        super(
          compose_message(
            'ambiguous_relationship',
            {
              klass: klass,
              inverse: inverse,
              name: name.inspect,
              candidates: candidates.map(&:inspect).join(', ')
            }
          )
        )
      end
    end
  end
end
