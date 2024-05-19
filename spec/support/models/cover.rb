# frozen_string_literal: true

class Cover
  include ActiveDocument::Document
  include ActiveDocument::Timestamps

  field :title, type: String

  embedded_in :book
end
