# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module ForeignKey
        # Foreign key strategy for has_one and has_many associations.
        # The foreign key is stored on the other side of the association.
        class None < Base
          SUFFIX = '_id'

          # @return [false] has_* associations don't store foreign keys on the owner
          def stores_foreign_key?
            false
          end

          # @return [nil] No field type since we don't create a field
          def field_type
            nil
          end

          # @return [String] '_id' (used for calculating FK name on the inverse)
          def suffix
            SUFFIX
          end

          # No-op: The foreign key is stored on the other side
          # @param _owner_class [Class] Ignored
          def create_field!(_owner_class)
            # No-op: FK is on the related document
          end

          # The foreign key field name on the related document
          # @return [String]
          def foreign_key
            @foreign_key ||= association.foreign_key_option || default_foreign_key
          end

          # No foreign key check for associations that don't store the FK
          # @return [nil]
          def foreign_key_check
            nil
          end

          # No index created on this side
          # @return [Hash]
          def index_spec
            {}
          end

          private

          def default_foreign_key
            # For has_* associations, the FK is on the inverse side
            # It's named after the inverse (which points back to us)
            if (inverse = association.inverse)
              "#{inverse}#{SUFFIX}"
            else
              "#{association.inverse_class_name.demodulize.underscore}#{SUFFIX}"
            end
          end
        end
      end
    end
  end
end
