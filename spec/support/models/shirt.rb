# frozen_string_literal: true

class Shirt
  include ActiveDocument::Document

  field :color, type: :string

  unalias_attribute :id

  field :id, type: :string
end
