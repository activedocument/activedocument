# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module Binding
        # Binding strategy for has_one and has_many associations.
        # Sets the foreign key on the related document (not the owner).
        class Has < Base
          # Bind a document to the association.
          # Sets foreign key on the related document and inverse reference.
          #
          # @param doc [ActiveDocument::Document] The document to bind (defaults to target)
          def bind_one(doc = target)
            return unless doc

            binding do
              bind_from_relational_parent(doc)
            end
          end

          # Unbind a document from the association.
          # Clears foreign key on the related document and inverse reference.
          #
          # @param doc [ActiveDocument::Document] The document to unbind (defaults to target)
          def unbind_one(doc = target)
            return unless doc

            binding do
              unbind_from_relational_parent(doc)
            end
          end

          private

          # Full binding from parent to child document.
          # @param doc [ActiveDocument::Document] The document to bind
          def bind_from_relational_parent(doc)
            check_mixed!(doc)
            check_inverse!(doc)
            remove_associated(doc)
            bind_foreign_key(doc, record_id(base))
            bind_polymorphic_type(doc, base.class.name)
            bind_inverse(doc, base)
          end

          # Check if trying to set an embedded document on a referenced association
          # @param doc [ActiveDocument::Document] The document to check
          # @raise [Errors::MixedRelations] If the doc is embedded
          def check_mixed!(doc)
            # Check if the document class has any embedded_in associations
            return unless doc.class.respond_to?(:embedded?) && doc.class.embedded?

            raise Errors::MixedRelations.new(base.class, doc.class)
          end

          # Full unbinding from parent to child document.
          # @param doc [ActiveDocument::Document] The document to unbind
          def unbind_from_relational_parent(doc)
            check_inverse!(doc)
            bind_foreign_key(doc, nil)
            bind_polymorphic_type(doc, nil)
            bind_inverse(doc, nil)
          end
        end
      end
    end
  end
end
