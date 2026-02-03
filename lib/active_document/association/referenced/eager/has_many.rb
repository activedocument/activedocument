# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module Eager
        # Eager loader for has_many associations.
        # Groups documents by primary key, collects multiple by foreign key.
        class HasMany < Base
          private

          def preload
            # Initialize all documents with empty array
            docs.each { |d| set_relation(d, []) }

            # Build a map of foreign key => documents
            entries = Hash.new { |hash, k| hash[k] = [] }
            each_loaded_document do |doc|
              fk = doc.send(key)
              entries[fk] << doc
            end

            # Set collections on parents and inverse on children
            entries.each do |id, matched_docs|
              set_on_parent(id, matched_docs)
            end
          end

          # Override to also set the inverse on each child document
          def set_on_parent(id, element)
            grouped_docs[id]&.each do |parent|
              set_relation(parent, element)
              # Set the inverse on each child to point back to the parent
              set_inverse_on_children(parent, element) if association.inverse && element.is_a?(Array)
            end
          end

          # Set the inverse relationship on each child document
          def set_inverse_on_children(parent, children)
            inverse_name = association.inverse
            children.each do |child|
              child.set_relation(inverse_name, parent) if child.is_a?(ActiveDocument::Document)
            end
          end

          # Use __build__ to set the relation for collections
          def set_relation(doc, element)
            doc.__build__(association.name, element, association) if doc.present?
          end

          # Group by primary key (on this document)
          def group_by_key
            association.primary_key
          end

          # Lookup by foreign key (on the target)
          def key
            association.foreign_key
          end
        end
      end
    end
  end
end
