# frozen_string_literal: true

class Cover
  include ActiveDocument::Document
  include ActiveDocument::Timestamps

  field :title, type: :string

  embedded_in :book
end
