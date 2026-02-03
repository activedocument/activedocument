# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module Proxy
        # Proxy for single-document associations (belongs_to_one, has_one).
        # Extends the base Association::One proxy with v2-specific behavior.
        class One < Association::One
          # Create a new single-document proxy.
          #
          # @param base [ActiveDocument::Document] The owning document
          # @param target [ActiveDocument::Document] The related document
          # @param association [Association] The association metadata
          def initialize(base, target, association)
            super do
              characterize_one(_target) if _target
              bind_one
            end
          end

          # Remove the association by clearing the foreign key.
          # FK is set in memory; user must save target document to persist.
          def nullify
            unbind_one
            # FK is cleared in memory by unbind_one; user must save target to persist
          end

          # Replace the current target with a new document.
          #
          # @param replacement [ActiveDocument::Document, Object, nil] The replacement document, ID, or nil
          # @return [self, nil] The proxy or nil if no replacement
          #
          # @raise [Errors::InverseRelationAssignmentDisallowed] If assigning from inverse side
          #   when allow_inverse_relation_assignment is false
          def substitute(replacement)
            # Check if we're assigning from the inverse (has_*) side
            check_inverse_assignment_allowed!

            # Handle nil assignment - unbind and clear the relation
            if replacement.nil?
              # Unbind first to clear FK and inverse references before
              # the document is potentially frozen by destroy
              unbind_one
              apply_dependent_option!(_target)
              # FK is cleared in memory; user must save target to persist
              self._target = nil
              return nil
            end

            new_target = normalize(replacement)

            # If reassigning the exact same object instance, do nothing
            return self if _target.equal?(new_target)

            # If both old and new targets are persisted with the same _id, this is
            # a re-assignment of the same document (different Ruby objects).
            # Just update the reference without modifying DB state.
            if _target&.persisted? && new_target.persisted? && _target._id == new_target._id
              @binding = nil
              self._target = new_target
              bind_one
              return self
            end

            # Unbind and apply dependent option to the old target
            old_target = _target
            unbind_one
            apply_dependent_option!(old_target)
            # FK is cleared in memory on old_target; user must save to persist

            # Clear cached binding and set new target
            @binding = nil
            self._target = new_target
            bind_one
            # FK is set in memory on new_target; user must save to persist
            self
          end

          private

          # Check if inverse relation assignment is allowed.
          # Raises error if assigning from has_* side when not allowed.
          #
          # @raise [Errors::InverseRelationAssignmentDisallowed] If not allowed
          def check_inverse_assignment_allowed!
            return if _association.stores_foreign_key? # belongs_to_* side - always OK
            return if _base.allow_inverse_relation_assignment?
            return if _binding? # Allow inverse setup during binding from belongs_to side

            raise Errors::InverseRelationAssignmentDisallowed.new(
              _association.name,
              _base.class,
              _association.relation_class
            )
          end

          # Apply the dependent option when clearing a relation.
          # Handles :destroy, :delete_all, :nullify, etc.
          #
          # @param doc [ActiveDocument::Document] The document to apply the action to
          def apply_dependent_option!(doc)
            return unless doc
            # Don't apply dependent action during build (only during create/save)
            return if _building?

            case _association.dependent
            when :destroy
              doc.destroy
            when :delete_all
              doc.delete
            when :nullify
              # nullify is handled by unbind_one; user must save to persist
            when :restrict_with_exception
              raise Errors::DeleteRestriction.new(doc, _association.name)
            when :restrict_with_error
              _base.errors.add(_association.name, :destroy_restrict_with_error_dependencies_exist)
            end
          end

          # Get the binding instance for this proxy.
          #
          # @return [Binding::Base] The binding object
          def binding
            @binding ||= _association.binder_class.new(_base, _target, _association)
          end

          # Normalize a replacement value to a document.
          #
          # @param replacement [ActiveDocument::Document, Object] The replacement
          # @return [ActiveDocument::Document] The normalized document
          def normalize(replacement)
            return replacement if replacement.is_a?(Document)

            _association.build(klass, replacement)
          end

          # Whether the association can be persisted.
          #
          # @return [Boolean]
          def persistable?
            _target&.persisted? && !_binding? && !_building?
          end

          class << self
            # Get the eager loader for this association type.
            #
            # @param association [Association] The association metadata
            # @param docs [Array<ActiveDocument::Document>] The documents to eager load
            # @return [Eager::Base] The eager loader
            def eager_loader(association, docs)
              association.eager_loader_class.new(association, docs)
            end

            # Whether this is an embedded association.
            #
            # @return [false] Always false for referenced associations
            def embedded?
              false
            end
          end
        end
      end
    end
  end
end
