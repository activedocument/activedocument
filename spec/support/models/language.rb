# frozen_string_literal: true

class Language
  include ActiveDocument::Document
  field :name, type: String
  embedded_in :translatable, polymorphic: true
end
