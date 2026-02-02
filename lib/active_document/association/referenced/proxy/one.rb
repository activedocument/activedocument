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
          # @param replacement [ActiveDocument::Document, Object] The replacement document or ID
          # @return [self, nil] The proxy or nil if no replacement
          def substitute(replacement)
            return self unless replacement

            new_target = normalize(replacement)

            # If reassigning the same document, do nothing
            return self if _target && _target._id == new_target._id

            # Unbind and save the old target
            old_target = _target
            unbind_one
            old_target&.save if old_target&.persisted? && old_target&.changed?

            # Clear cached binding and set new target
            @binding = nil
            self._target = new_target
            bind_one
            save_target_if_persistable
            self
          end

          # Save the target document if the base is persisted and we're not in a
          # building block.
          def save_target_if_persistable
            return unless persistable?

            _target.save
          end

          # Save the target when the base is persisted (for has_one/has_many).
          # This persists the FK on the target document.
          def save_target_if_base_persisted
            return unless _base&.persisted? && _target&.persisted?
            return if _building?

            # Only save if the target has FK changes
            return unless _target.changed?

            _target.save
          end

          private

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
