# frozen_string_literal: true

class House
  include ActiveDocument::Document
  field :name, type: String
  field :model, type: String
  default_scope -> { asc(:name) }
end
