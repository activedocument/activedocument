# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module ForeignKey
        # Foreign key strategy for belongs_to_many associations.
        # Stores an array of IDs referencing multiple documents.
        class Array < Base
          SUFFIX = '_ids'

          # @return [true] belongs_to_many stores foreign keys
          def stores_foreign_key?
            true
          end

          # @return [Array] Field type for array of IDs
          def field_type
            ::Array
          end

          # @return [String] '_ids'
          def suffix
            SUFFIX
          end

          # Create the foreign key field on the owner class
          # @param owner_class [Class] The class to create the field on
          def create_field!(owner_class)
            # Register this field as an aliased association for the inverse
            owner_class.aliased_associations[foreign_key] = association.name.to_s

            owner_class.field(
              foreign_key,
              type: field_type,
              identity: true,
              overwrite: true,
              association: association,
              default: nil
            )
          end

          # The inverse foreign key field name (for bidirectional sync)
          # @return [String, nil]
          def inverse_foreign_key
            @inverse_foreign_key ||= calculate_inverse_foreign_key
          end

          # The inverse foreign key setter method name
          # @return [String, nil]
          def inverse_foreign_key_setter
            "#{inverse_foreign_key}=" if inverse_foreign_key
          end

          private

          def default_foreign_key
            "#{association.name.to_s.singularize}#{SUFFIX}"
          end

          def calculate_inverse_foreign_key
            if association.options.key?(:inverse_foreign_key)
              association.options.inverse_foreign_key
            elsif association.options.key?(:inverse_of) && association.options.inverse_of
              "#{association.options.inverse_of.to_s.singularize}#{SUFFIX}"
            elsif (inv = association.inverse_association&.foreign_key)
              inv
            else
              "#{association.inverse_class_name.demodulize.underscore}#{SUFFIX}"
            end
          end
        end
      end
    end
  end
end
