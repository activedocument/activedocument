# frozen_string_literal: true

class Pub
  include ActiveDocument::Document
  include ActiveDocument::Attributes::Dynamic
  field :location, type: :array
  index location: '2dsphere'
end
