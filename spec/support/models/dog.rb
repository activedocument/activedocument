# frozen_string_literal: true

class Dog
  include ActiveDocument::Document
  field :name, type: :string
  has_and_belongs_to_many :breeds
  has_and_belongs_to_many :fire_hydrants, primary_key: :location
  default_scope -> { asc(:name) }
end
