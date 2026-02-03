# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module Eager
        # Eager loader for has_one associations.
        # Groups documents by primary key, loads by foreign key.
        class HasOne < Base
          private

          def preload
            # Initialize all documents with nil
            docs.each { |d| set_relation(d, nil) }

            # Load and set each document
            each_loaded_document do |doc|
              id = doc.send(key)
              set_on_parent(id, doc)
            end
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
