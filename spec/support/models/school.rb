# frozen_string_literal: true

class School
  include ActiveDocument::Document

  has_many :students

  field :district, type: :string
  field :team, type: :string

  field :after_destroy_triggered, default: false

  accepts_nested_attributes_for :students, allow_destroy: true
end
