# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module Binding
        # Binding strategy for belongs_to_many associations.
        # Manages arrays of foreign keys on both sides (bidirectional).
        class ManyToMany < Base
          # Bind a document to the association.
          # Adds the base's ID to the document's inverse foreign key array.
          #
          # @param doc [ActiveDocument::Document] The document to bind
          def bind_one(doc)
            return unless doc

            binding do
              inverse_keys = try_method(doc, association.inverse_foreign_key) unless doc.frozen?

              if inverse_keys
                inv_record_id = inverse_record_id(doc)
                unless inverse_keys.include?(inv_record_id)
                  try_method(doc, association.inverse_foreign_key_setter, inverse_keys.push(inv_record_id))
                end
                doc.reset_relation_criteria(association.inverse)
              end

              # Mark both sides as synced to prevent redundant updates
              base._synced[association.foreign_key] = true
              doc._synced[association.inverse_foreign_key] = true if association.inverse_foreign_key
            end
          end

          # Unbind a document from the association.
          # Removes the IDs from both foreign key arrays.
          #
          # @param doc [ActiveDocument::Document] The document to unbind
          def unbind_one(doc)
            return unless doc

            binding do
              # Remove doc's ID from base's foreign key array
              base.send(association.foreign_key).delete_one(record_id(doc))

              # Remove base's ID from doc's inverse foreign key array
              inverse_keys = try_method(doc, association.inverse_foreign_key) unless doc.frozen?
              if inverse_keys
                inverse_keys.delete_one(inverse_record_id(doc))
                doc.reset_relation_criteria(association.inverse)
              end

              # Mark both sides as synced
              base._synced[association.foreign_key] = true
              doc._synced[association.inverse_foreign_key] = true if association.inverse_foreign_key && !doc.frozen?
            end
          end

          private

          # Get the ID to use for the inverse relationship.
          # Uses inverse_primary_key option if set, otherwise determines from inverse association.
          #
          # @param doc [ActiveDocument::Document] The document context
          # @return [Object] The ID value
          def inverse_record_id(doc)
            if (pk = association.options.inverse_primary_key)
              base.send(pk)
            else
              inverse_association = determine_inverse_association(doc)
              if inverse_association
                base.public_send(inverse_association.primary_key)
              else
                base._id
              end
            end
          end

          # Find the inverse association for a document.
          #
          # @param doc [ActiveDocument::Document] The document
          # @return [ActiveDocument::Association::Relatable, nil] The inverse association
          def determine_inverse_association(doc)
            doc.relations[base.class.name.demodulize.underscore.pluralize]
          end
        end
      end
    end
  end
end
