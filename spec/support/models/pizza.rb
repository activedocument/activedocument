# frozen_string_literal: true

class Pizza
  include ActiveDocument::Document
  field :name, type: :string
  has_one :topping, autosave: true
  validates_presence_of :topping
  accepts_nested_attributes_for :topping
end
