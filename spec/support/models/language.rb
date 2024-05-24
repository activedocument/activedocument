# frozen_string_literal: true

class Language
  include ActiveDocument::Document
  field :name, type: :string
  embedded_in :translatable, polymorphic: true
end
