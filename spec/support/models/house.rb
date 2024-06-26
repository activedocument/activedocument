# frozen_string_literal: true

class House
  include ActiveDocument::Document
  field :name, type: :string
  field :model, type: :string
  default_scope -> { asc(:name) }
end
