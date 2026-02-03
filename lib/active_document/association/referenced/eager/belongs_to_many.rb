# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module Eager
        # Eager loader for belongs_to_many associations.
        # Groups documents by foreign key array, loads by primary key.
        class BelongsToMany < Base
          private

          def preload
            # Initialize all documents with empty array
            docs.each { |d| set_relation(d, []) }

            # Build a map of primary key => document
            entries = {}
            each_loaded_document do |doc|
              entries[doc.send(key)] = doc
            end

            # For each parent document, collect matching documents by FK array
            docs.each do |d|
              keys = d.send(group_by_key) || []
              matched_docs = entries.values_at(*keys).compact
              set_relation(d, matched_docs)
            end
          end

          # Collect all keys from all documents' FK arrays
          def keys_from_docs
            keys = Set.new
            docs.each do |d|
              fk_array = d.send(group_by_key)
              keys += fk_array if fk_array
            end
            keys.to_a
          end

          # Use __build__ to set the relation for collections
          def set_relation(doc, element)
            doc.__build__(association.name, element, association) if doc.present?
          end

          # Group by foreign key array (stored on this document)
          def group_by_key
            association.foreign_key
          end

          # Lookup by primary key (on the target)
          def key
            association.primary_key
          end
        end
      end
    end
  end
end
