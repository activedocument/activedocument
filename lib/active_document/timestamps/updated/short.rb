# frozen_string_literal: true

module ActiveDocument
  module Timestamps
    module Updated

      # Adds an updated_at timestamp to the document, but it is stored as u_at
      # with an updated_at alias.
      module Short
        extend ActiveSupport::Concern

        included do
          include Updated
          fields.delete('updated_at')
          field :u_at, type: :time, as: :updated_at
        end
      end
    end
  end
end
