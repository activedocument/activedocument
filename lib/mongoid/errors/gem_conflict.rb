# frozen_string_literal: true

module Mongoid
  module Errors

    # Raised when a disallowed gem is present in the bundle.
    class GemConflict < MongoidError
      def initialize(gem_name)
        super(
          compose_message('gem_conflict', this_gem: ::Mongoid::GEM_NAME, other_gem: gem_name)
        )
      end
    end
  end
end
