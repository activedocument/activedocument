# frozen_string_literal: true

require 'active_document/timestamps/created/short'

module ActiveDocument
  module Timestamps
    # This module handles the behavior for setting up document created at
    # timestamp.
    module Created
      extend ActiveSupport::Concern

      included do
        include ActiveDocument::Timestamps::Timeless

        field :created_at, type: :time
        set_callback :create, :before, :set_created_at
      end

      # Update the created_at field on the Document to the current time. This is
      # only called on create.
      #
      # @example Set the created at time.
      #   person.set_created_at
      def set_created_at
        if !timeless? && !created_at
          now = Time.current
          self.updated_at = now if is_a?(Updated) && !updated_at_changed?
          self.created_at = now
        end
        clear_timeless_option
      end
    end
  end
end
