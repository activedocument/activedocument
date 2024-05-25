# frozen_string_literal: true

class Dictionary
  include ActiveDocument::Document
  field :name, type: :string
  field :publisher, type: :string
  field :year, type: :integer

  # This field must be a Time
  field :published, type: :time

  # This field must be a Date
  field :submitted_on, type: :date

  field :description, type: :string, localize: true
  field :l, type: :string, as: :language
  has_many :words, validate: false
end
