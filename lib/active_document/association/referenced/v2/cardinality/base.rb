# frozen_string_literal: true

module ActiveDocument
  module Association
    module Referenced
      module V2
        module Cardinality
          # Base class for cardinality strategies.
          # Defines whether the association returns one or many documents.
          class Base
            attr_reader :association

            # @param association [Association] The association this strategy belongs to
            def initialize(association)
              @association = association
            end

            # Whether this association returns multiple documents
            # @return [Boolean]
            def many?
              raise NotImplementedError, "#{self.class} must implement #many?"
            end

            # Whether this association returns a single document
            # @return [Boolean]
            def one?
              !many?
            end

            # The nested builder class for accepts_nested_attributes_for
            # @return [Class]
            def nested_builder_class
              raise NotImplementedError, "#{self.class} must implement #nested_builder_class"
            end
          end
        end
      end
    end
  end
end
