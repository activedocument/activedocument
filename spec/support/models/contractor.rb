# frozen_string_literal: true

class Contractor
  include ActiveDocument::Document
  embedded_in :building
  field :name, type: String
end
