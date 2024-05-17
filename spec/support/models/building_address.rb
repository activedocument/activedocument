# frozen_string_literal: true

class BuildingAddress
  include ActiveDocument::Document
  field :city, type: String

  embedded_in :building
  validates_presence_of :city
end
