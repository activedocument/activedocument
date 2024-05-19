# frozen_string_literal: true

module ActiveDocument
  module Association
    module Embedded

      # This module provides convenience macros for using cyclic embedded
      # associations.
      module Cyclic
        extend ActiveSupport::Concern

        included do
          class_attribute :cyclic
        end

        module ClassMethods

          # Create a cyclic embedded association that creates a tree hierarchy for
          # the document and many embedded child documents.
          #
          # @example Set up a recursive embeds many.
          #
          #   class Role
          #     include ActiveDocument::Document
          #     recursively_embeds_many
          #   end
          #
          # @example The previous example is a shortcut for this.
          #
          #   class Role
          #     include ActiveDocument::Document
          #     embeds_many :child_roles, :class_name => "Role", :cyclic => true
          #     embedded_in :parent_role, :class_name => "Role", :cyclic => true
          #   end
          #
          # This provides the default nomenclature for accessing a parent document
          # or its children.
          def recursively_embeds_many(options = {})
            embeds_many(
              cyclic_child_name,
              options.merge(class_name: name, cyclic: true)
            )
            embedded_in cyclic_parent_name, class_name: name, cyclic: true
          end

          # Create a cyclic embedded association that creates a single self
          # referencing relationship for a parent and a single child.
          #
          # @example Set up a recursive embeds one.
          #
          #   class Role
          #     include ActiveDocument::Document
          #     recursively_embeds_one
          #   end
          #
          # @example The previous example is a shortcut for this.
          #
          #   class Role
          #     include ActiveDocument::Document
          #     embeds_one :child_role, :class_name => "Role", :cyclic => true
          #     embedded_in :parent_role, :class_name => "Role", :cyclic => true
          #   end
          #
          # This provides the default nomenclature for accessing a parent document
          # or its children.
          def recursively_embeds_one(options = {})
            embeds_one(
              cyclic_child_name(false),
              options.merge(class_name: name, cyclic: true)
            )
            embedded_in cyclic_parent_name, class_name: name, cyclic: true
          end

          private

          # Determines the parent name given the class.
          #
          # @example Determine the parent name.
          #   Role.cyclic_parent_name
          #
          # @return [ String ] "parent_" plus the class name underscored.
          def cyclic_parent_name
            :"parent_#{name.demodulize.underscore.singularize}"
          end

          # Determines the child name given the class.
          #
          # @example Determine the child name.
          #   Role.cyclic_child_name
          #
          # @param [ true | false ] many Is the a many association?
          #
          # @return [ String ] "child_" plus the class name underscored in
          #   singular or plural form.
          def cyclic_child_name(many = true)
            :"child_#{name.demodulize.underscore.send(many ? :pluralize : :singularize)}"
          end
        end
      end
    end
  end
end
