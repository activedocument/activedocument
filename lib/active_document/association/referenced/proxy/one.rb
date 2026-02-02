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
              save_target_if_base_persisted
            end
          end

          # Remove the association by clearing the foreign key.
          # Saves the target document.
          def nullify
            unbind_one
            _target&.save
          end

          # Replace the current target with a new document.
          #
          # @param replacement [ActiveDocument::Document, Object, nil] The replacement document, ID, or nil
          # @return [self, nil] The proxy or nil if no replacement
          def substitute(replacement)
            # Handle nil assignment - unbind and clear the relation
            if replacement.nil?
              # Unbind first to clear FK and inverse references before
              # the document is potentially frozen by destroy
              unbind_one
              apply_dependent_option!(_target)
              _target&.save if _target&.persisted? && _target&.changed?
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
            old_target&.save if old_target&.persisted? && old_target&.changed?

            # Clear cached binding and set new target
            @binding = nil
            self._target = new_target
            bind_one
            save_target_if_persistable
            self
          end

          # Save the target document if the base is persisted.
          # This handles both new documents (insert) and existing documents (update).
          def save_target_if_persistable
            return unless _base&.persisted? && _target
            return if _binding? || _building?

            # Save if target is new or has changes
            _target.save if _target.new_record? || _target.changed?
          end

          # Save the target when the base is persisted (for has_one/has_many).
          # This persists the FK on the target document.
          def save_target_if_base_persisted
            return unless _base&.persisted? && _target
            return if _building?

            # Save if target is new or has changes
            _target.save if _target.new_record? || _target.changed?
          end

          private

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
              # nullify is handled by unbind_one + save
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
