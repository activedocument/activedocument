# frozen_string_literal: true

class Manufacturer
  include ActiveDocument::Document

  field :products, type: :array, default: []

  validates_presence_of :products
end
