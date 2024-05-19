# frozen_string_literal: true

class Bar
  include ActiveDocument::Document
  include ActiveDocument::Attributes::Dynamic
  field :name, type: String
  field :location, type: Array
  field :lat_lng, type: LatLng

  has_one :rating, as: :ratable
  index location: '2d'
end
