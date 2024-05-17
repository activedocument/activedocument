# frozen_string_literal: true

class Translation
  include ActiveDocument::Document
  field :language
  embedded_in :name
end
