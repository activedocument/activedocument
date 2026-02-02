# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module V2
        module Cardinality
          # Cardinality strategy for single-document associations.
          # Used by belongs_to_one and has_one.
          class One < Base
            # @return [false] Single document, not many
            def many?
              false
            end

            # @return [true] Returns a single document
            def one?
              true
            end

            # @return [Class] Nested::One for single document nesting
            def nested_builder_class
              ActiveDocument::Association::Nested::One
            end

            # Default validation for single-document associations
            # belongs_to_one: false by default (historically)
            # has_one: true by default
            # @return [Boolean]
            def validation_default
              # This is overridden based on association type in the Association class
              false
            end
          end
        end
      end
    end
  end
end
