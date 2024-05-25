# frozen_string_literal: true

class Purse
  include ActiveDocument::Document

  field :brand, type: :string

  embedded_in :person
end
