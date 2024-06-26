# frozen_string_literal: true

class Symptom
  include ActiveDocument::Document
  field :name, type: :string
  embedded_in :person
  default_scope -> { asc(:name) }
end
