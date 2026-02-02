# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module V2
        module ForeignKey
          # Foreign key strategy for belongs_to_one associations.
          # Stores a single ID referencing one document.
          class Single < Base
            SUFFIX = '_id'

            # @return [true] belongs_to_one stores a foreign key
            def stores_foreign_key?
              true
            end

            # @return [Object] Field type for single ID storage
            def field_type
              Object
            end

            # @return [String] '_id'
            def suffix
              SUFFIX
            end

            # Create the foreign key field on the owner class
            # @param owner_class [Class] The class to create the field on
            def create_field!(owner_class)
              owner_class.field(
                foreign_key,
                type: field_type,
                identity: true,
                overwrite: true,
                association: association,
                default: nil
              )
            end

            # Index spec includes polymorphic type if applicable
            # @return [Hash]
            def index_spec
              if association.polymorphic?
                { foreign_key => 1, association.inverse_type => 1 }
              else
                { foreign_key => 1 }
              end
            end

            private

            def default_foreign_key
              "#{association.name}#{SUFFIX}"
            end
          end
        end
      end
    end
  end
end
