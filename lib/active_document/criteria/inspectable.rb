# frozen_string_literal: true

module ActiveDocument
  class Criteria

    # Mixin module included in ActiveDocument::Criteria which adds custom
    # +#inspect+ method functionality.
    module Inspectable

      # Get a pretty string representation of the criteria, including the
      # selector, options, matching count and documents for inspection.
      #
      # @example Inspect the criteria.
      #   criteria.inspect
      #
      # @return [ String ] The inspection string.
      def inspect
        <<~INSPECT
          #<ActiveDocument::Criteria
            selector: #{selector.inspect}
            options:  #{options.inspect}
            class:    #{klass}
            embedded: #{embedded?}>
        INSPECT
      end
    end
  end
end
