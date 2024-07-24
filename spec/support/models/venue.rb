# frozen_string_literal: true

class Venue
  include ActiveDocument::Document
  field :name, type: :string
  field :area, type: :integer
end
