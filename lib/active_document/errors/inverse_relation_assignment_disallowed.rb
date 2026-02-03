# frozen_string_literal: true

module ActiveDocument
  module Errors

    # This error is raised when attempting to modify an association from the
    # inverse (has_*) side when allow_inverse_relation_assignment is false.
    class InverseRelationAssignmentDisallowed < BaseError

      # Create the new error.
      #
      # @param [ Symbol ] association_name The name of the association that was
      #   modified from the inverse side.
      # @param [ Class ] base_class The class that owns the has_* association.
      # @param [ Class ] target_class The class that owns the belongs_to_* association.
      def initialize(association_name, base_class, target_class)
        super(
          compose_message(
            'inverse_relation_assignment_disallowed',
            {
              association: association_name,
              base_class: base_class,
              target_class: target_class
            }
          )
        )
      end
    end
  end
end
