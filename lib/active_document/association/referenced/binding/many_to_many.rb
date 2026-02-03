# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module Binding
        # Binding strategy for belongs_to_many associations.
        # Manages the FK array on the belongs_to_many side only.
        # The inverse (has_many) side has no FK - it queries via the inverse.
        class ManyToMany < Base
          # Bind a document to the association.
          # Adds the doc's ID to the base's FK array.
          # No inverse FK sync - belongs_to_many pairs with has_many, not another belongs_to_many.
          #
          # @param doc [ActiveDocument::Document] The document to bind
          def bind_one(doc)
            return unless doc

            binding do
              # Add doc's ID to base's foreign key array (e.g., dog.park_ids << park._id)
              base_keys = base.send(association.foreign_key)
              doc_id = record_id(doc)
              base_keys.push(doc_id) unless base_keys.include?(doc_id)

              # Mark as synced to prevent redundant updates
              base._synced[association.foreign_key] = true
            end
          end

          # Unbind a document from the association.
          # Removes the doc's ID from the base's FK array.
          # No inverse FK sync needed.
          #
          # @param doc [ActiveDocument::Document] The document to unbind
          def unbind_one(doc)
            return unless doc

            binding do
              # Remove doc's ID from base's foreign key array
              base.send(association.foreign_key).delete_one(record_id(doc))

              # Mark as synced
              base._synced[association.foreign_key] = true
            end
          end
        end
      end
    end
  end
end
