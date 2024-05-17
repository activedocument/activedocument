# frozen_string_literal: true

class Definition
  include ActiveDocument::Document
  field :description, type: String
  field :p, as: :part, type: String
  field :regular, type: ActiveDocument::Boolean
  field :syn, as: :synonyms, localize: true, type: String
  field :active, type: ActiveDocument::Boolean, localize: true, default: true
  embedded_in :word
end
