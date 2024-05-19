# frozen_string_literal: true

class Pronunciation
  include ActiveDocument::Document
  field :sound, type: String
  embedded_in :word
end
