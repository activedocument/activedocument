# frozen_string_literal: true

class Scribe
  include ActiveDocument::Document
  field :name, type: :string
  embedded_in :owner
end
