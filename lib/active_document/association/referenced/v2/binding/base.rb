# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module V2
        module Binding
          # Base class for binding strategies.
          # Handles synchronization of foreign keys and inverse references.
          class Base
            include ActiveDocument::Threaded::Lifecycle

            attr_reader :base, :target, :association

            # @param base [ActiveDocument::Document] The owning document
            # @param target [ActiveDocument::Document, Array] The related document(s)
            # @param association [Association] The association metadata
            def initialize(base, target, association)
              @base = base
              @target = target
              @association = association
            end

            # Bind a single document
            # @param doc [ActiveDocument::Document] The document to bind (defaults to target)
            def bind_one(doc = target)
              raise NotImplementedError, "#{self.class} must implement #bind_one"
            end

            # Unbind a single document
            # @param doc [ActiveDocument::Document] The document to unbind (defaults to target)
            def unbind_one(doc = target)
              raise NotImplementedError, "#{self.class} must implement #unbind_one"
            end

            protected

            # Execute the provided block inside a binding context.
            # Prevents recursive binding operations.
            # @yield The block to execute
            # @return [Object] The result of the block
            def binding
              return if _binding?

              _binding { yield(self) if block_given? }
            end

            # Set the foreign key on a document
            # @param keyed [ActiveDocument::Document] The document that stores the FK
            # @param id [Object] The ID value to set
            def bind_foreign_key(keyed, id)
              return if keyed.frozen?

              try_method(keyed, association.foreign_key_setter, id)
            end

            # Set the polymorphic type field
            # @param typed [ActiveDocument::Document] The document that stores the type
            # @param name [String] The class name
            def bind_polymorphic_type(typed, name)
              return unless association.type_setter && !typed.frozen?

              try_method(typed, association.type_setter, name)
            end

            # Set the polymorphic inverse type field
            # @param typed [ActiveDocument::Document] The document that stores the type
            # @param name [String] The class name or key
            def bind_polymorphic_inverse_type(typed, name)
              return unless association.inverse_type_setter && !typed.frozen?

              try_method(typed, association.inverse_type_setter, name)
            end

            # Bind the inverse reference in memory
            # @param doc [ActiveDocument::Document] The document to set the inverse on
            # @param inverse [ActiveDocument::Document] The inverse document
            def bind_inverse(doc, inverse)
              inverse_setter = association.inverse_setter(doc)
              return unless doc.respond_to?(inverse_setter) && !doc.frozen?

              try_method(doc, inverse_setter, inverse)
            end

            # Get the record ID from a document using the primary key
            # @param doc [ActiveDocument::Document] The document
            # @return [Object] The primary key value
            def record_id(doc)
              doc.public_send(association.primary_key)
            end

            # Check if the inverse is properly defined for binding
            # @param doc [ActiveDocument::Document] The document to check
            # @raise [Errors::InverseNotFound] If no valid inverse found
            def check_inverse!(doc)
              return if association.bindable?(doc)

              raise Errors::InverseNotFound.new(
                base.class,
                association.name,
                doc.class,
                association.foreign_key
              )
            end

            # Remove the document from its current inverse association
            # @param doc [ActiveDocument::Document] The document to remove
            def remove_associated(doc)
              return unless (inverse = association.inverse(doc))

              if association.many?
                remove_associated_many(doc, inverse)
              elsif association.in_to?
                remove_associated_in_to(doc, inverse)
              end
            end

            # Remove from a *_many inverse
            # @param doc [ActiveDocument::Document] The document to remove
            # @param inverse [Symbol] The inverse association name
            def remove_associated_many(doc, inverse)
              return unless (inv = doc.ivar(inverse)) &&
                            (base != inv && (associated = inv.ivar(association.name)))

              associated.delete(doc)
            end

            # Remove from a belongs_to/embedded_in inverse
            # @param doc [ActiveDocument::Document] The document to remove
            # @param inverse [Symbol] The inverse association name
            def remove_associated_in_to(doc, inverse)
              return unless (associated = doc.ivar(inverse))

              associated.send(association.setter, nil)
            end

            # Try to call a method if it exists
            # @param object [Object] The object to call on
            # @param method_name [String, Symbol] The method name
            # @param args [Array] The arguments
            # @return [Object, nil] The result or nil
            def try_method(object, method_name, *args)
              object.try(method_name, *args) if method_name
            end

            # Set the base association for correct inverse handling
            # @return [Boolean] Whether the association changed
            def set_base_association
              inverse_association = association.inverse_association(target)
              return unless inverse_association != association && !inverse_association.nil?

              base._association = inverse_association
            end
          end
        end
      end
    end
  end
end
