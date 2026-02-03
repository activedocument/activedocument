# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module Eager
        # Eager loader for belongs_to_one associations.
        # Groups documents by foreign key, loads by primary key.
        class BelongsTo < Base
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

          # For polymorphic associations, load documents grouped by type.
          def each_loaded_document(&block)
            if association.polymorphic?
              keys_by_type_from_docs.each do |type, keys|
                each_loaded_document_of_class(Object.const_get(type), keys, &block)
              end
            else
              super
            end
          end

          # Get keys grouped by polymorphic type.
          #
          # @return [Hash] Type name => array of keys
          def keys_by_type_from_docs
            inverse_type_field = association.inverse_type

            docs.each_with_object({}) do |doc, keys_by_type|
              next unless doc.respond_to?(inverse_type_field) && doc.respond_to?(group_by_key)

              inverse_type_name = doc.send(inverse_type_field)
              next if inverse_type_name.nil?

              key_value = doc.send(group_by_key)
              next unless key_value

              keys_by_type[inverse_type_name] ||= []
              keys_by_type[inverse_type_name].push(key_value)
            end
          end

          # Load documents of a specific class.
          #
          # @param cls [Class] The class to load
          # @param keys [Array] The keys to load
          def each_loaded_document_of_class(cls, keys, &block)
            return if keys.empty?

            criteria = cls.criteria
            criteria = criteria.apply_scope(association.scope)
            criteria = criteria.any_in(key => keys)
            criteria.inclusions = criteria.inclusions - [association]
            criteria.each(&block)
          end

          # Group by foreign key (stored on the document)
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
