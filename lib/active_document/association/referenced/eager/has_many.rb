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

            # Set collections on parents
            entries.each do |id, matched_docs|
              set_on_parent(id, matched_docs)
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
