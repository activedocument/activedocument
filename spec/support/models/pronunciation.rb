# frozen_string_literal: true

class Pronunciation
  include ActiveDocument::Document
  field :sound, type: :string
  embedded_in :word
end
