# frozen_string_literal: true

module ActiveDocument
  module Timestamps
    module Created

      # Adds a created_at timestamp to the document, but it is stored as c_at
      # with a created_at alias.
      module Short
        extend ActiveSupport::Concern

        included do
          include Created
          fields.delete('created_at')
          field :c_at, type: :time, as: :created_at
        end
      end
    end
  end
end
