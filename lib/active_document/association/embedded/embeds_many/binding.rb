# frozen_string_literal: true

module ActiveDocument
  module Association
    module Embedded
      class EmbedsMany

        # Binding class for all embeds_many associations.
        class Binding
          include Bindable

          # Binds a single document with the inverse association. Used
          # specifically when appending to the proxy.
          #
          # @example Bind one document.
          #   person.addresses.bind_one(address)
          #
          # @param [ ActiveDocument::Document ] doc The single document to bind.
          def bind_one(doc)
            doc.parentize(_base)
            binding do
              remove_associated(doc)
              try_method(doc, _association.inverse_setter(_target), _base)
            end
          end

          # Unbind a single document.
          #
          # @example Unbind the document.
          #   person.addresses.unbind_one(document)
          #
          # @param [ ActiveDocument::Document ] doc The single document to unbind.
          def unbind_one(doc)
            binding do
              try_method(doc, _association.inverse_setter(_target), nil)
            end
          end
        end
      end
    end
  end
end
