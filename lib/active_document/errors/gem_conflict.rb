# frozen_string_literal: true

module ActiveDocument
  module Errors

    # Raised when a disallowed gem is present in the bundle.
    class GemConflict < BaseError
      def initialize(gem_name)
        super(
          compose_message('gem_conflict', this_gem: ::ActiveDocument::GEM_NAME, other_gem: gem_name)
        )
      end
    end
  end
end
