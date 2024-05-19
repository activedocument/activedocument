# frozen_string_literal: true

class Shirt
  include ActiveDocument::Document

  field :color, type: String

  unalias_attribute :id

  field :id, type: String
end
