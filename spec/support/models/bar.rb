# frozen_string_literal: true

class Bar
  include ActiveDocument::Document
  include ActiveDocument::Attributes::Dynamic
  field :name, type: :string
  field :location, type: :array
  field :lat_lng, type: LatLng

  has_one :rating, as: :ratable
  index location: '2d'
end
