# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      class HasMany

        # Eager class for has_many associations.
        class Eager < Association::Eager

          private

          def preload
            @docs.each do |d|
              set_relation(d, [])
            end

            entries = Hash.new { |hash, key| hash[key] = [] }
            each_loaded_document do |doc|
              fk = doc.send(key)
              entries[fk] << doc
            end

            entries.each do |id, docs|
              set_on_parent(id, docs)
            end
          end

          def set_relation(doc, element)
            doc.__build__(@association.name, element, @association) if doc.present?
          end

          def group_by_key
            @association.primary_key
          end

          def key
            @association.foreign_key
          end
        end
      end
    end
  end
end
