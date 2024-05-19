# frozen_string_literal: true

class Rating
  include ActiveDocument::Document
  field :value, type: Integer
  belongs_to :ratable, polymorphic: true
  has_many :comments
  validates_numericality_of :value, less_than: 100, allow_nil: true
  validates :ratable, associated: true
end
