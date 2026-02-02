# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module ForeignKey
        # Base class for foreign key storage strategies.
        # Subclasses define how foreign keys are stored and managed.
        class Base
          attr_reader :association

          # @param association [Association] The association this strategy belongs to
          def initialize(association)
            @association = association
          end

          # Whether this association stores a foreign key on the owning document
          # @return [Boolean]
          def stores_foreign_key?
            raise NotImplementedError, "#{self.class} must implement #stores_foreign_key?"
          end

          # The type of the foreign key field
          # @return [Class, nil]
          def field_type
            raise NotImplementedError, "#{self.class} must implement #field_type"
          end

          # The suffix used for default foreign key names
          # @return [String]
          def suffix
            raise NotImplementedError, "#{self.class} must implement #suffix"
          end

          # The foreign key field name
          # @return [String]
          def foreign_key
            @foreign_key ||= association.foreign_key_option || default_foreign_key
          end

          # The foreign key setter method name
          # @return [String]
          def foreign_key_setter
            "#{foreign_key}="
          end

          # The method to check if foreign key has changed
          # @return [String]
          def foreign_key_check
            "#{foreign_key}_previously_changed?"
          end

          # Create the foreign key field on the owner class
          # @param owner_class [Class] The class to create the field on
          def create_field!(owner_class)
            raise NotImplementedError, "#{self.class} must implement #create_field!"
          end

          # The index specification for the foreign key
          # @return [Hash]
          def index_spec
            { foreign_key => 1 }
          end

          private

          # Calculate the default foreign key name
          # @return [String]
          def default_foreign_key
            raise NotImplementedError, "#{self.class} must implement #default_foreign_key"
          end
        end
      end
    end
  end
end
