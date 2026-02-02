# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module V2
        module Cardinality
          # Cardinality strategy for multi-document associations.
          # Used by belongs_to_many and has_many.
          class Many < Base
            # @return [true] Returns multiple documents
            def many?
              true
            end

            # @return [false] Not a single document
            def one?
              false
            end

            # @return [Class] Nested::Many for collection nesting
            def nested_builder_class
              ActiveDocument::Association::Nested::Many
            end
          end
        end
      end
    end
  end
end
