# frozen_string_literal: true

class Exhibitor
  include ActiveDocument::Document
  field :status, type: :string
  belongs_to :exhibition
  has_and_belongs_to_many :artworks
end
