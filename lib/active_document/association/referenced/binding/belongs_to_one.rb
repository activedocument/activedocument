# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module Binding
        # Binding strategy for belongs_to_one associations.
        # Sets the foreign key on the owning document and manages inverse.
        class BelongsToOne < Base
          # Bind the target document to the base.
          # Sets foreign key on base, polymorphic type, and inverse reference.
          #
          # @param doc [ActiveDocument::Document] The document to bind (defaults to target)
          def bind_one(doc = target)
            return unless doc

            binding do
              check_polymorphic_inverses!(doc)
              bind_foreign_key(base, record_id(doc))

              # Set the inverse type for polymorphic associations
              if association.inverse_type_setter && !base.frozen?
                key = association.resolver&.default_key_for(doc) || doc.class.name
                bind_polymorphic_inverse_type(base, key)
              end

              # Set up the inverse relationship
              if (inverse = association.inverse(doc)) && set_base_association
                if base.referenced_many?
                  doc.public_send(inverse).push(base)
                else
                  remove_associated(doc)
                  doc.set_relation(inverse, base)
                end
              end
            end
          end

          # Unbind the target document from the base.
          # Clears foreign key, polymorphic type, and inverse reference.
          #
          # @param doc [ActiveDocument::Document] The document to unbind (defaults to target)
          def unbind_one(doc = target)
            return unless doc

            binding do
              inverse = association.inverse(doc)
              bind_foreign_key(base, nil)
              bind_polymorphic_inverse_type(base, nil)

              if inverse
                set_base_association
                if base.referenced_many?
                  doc.public_send(inverse).delete(base)
                else
                  doc.set_relation(inverse, nil)
                end
              end
            end
          end

          private

          # Check for problems with multiple inverse definitions on polymorphic associations.
          #
          # @param doc [ActiveDocument::Document] The document to check
          # @raise [Errors::InvalidSetPolymorphicRelation] If ambiguous inverses
          def check_polymorphic_inverses!(doc)
            inverses = association.inverses(doc)
            return unless inverses.length > 1 && base.send(association.foreign_key).nil?

            raise Errors::InvalidSetPolymorphicRelation.new(
              association.name, base.class.name, doc.class.name
            )
          end
        end
      end
    end
  end
end
