# frozen_string_literal: true

module ActiveDocument
  module Errors

    # This error is raised when trying to create set nested documents above the
    # specified :limit
    #
    # @example Create the error.
    #   TooManyNestedAttributeRecords.new('association', limit)
    class TooManyNestedAttributeRecords < BaseError
      def initialize(association, limit)
        super(
          compose_message(
            'too_many_nested_attribute_records',
            { association: association, limit: limit }
          )
        )
      end
    end
  end
end
