# frozen_string_literal: true

class Symptom
  include ActiveDocument::Document
  field :name, type: String
  embedded_in :person
  default_scope -> { asc(:name) }
end
