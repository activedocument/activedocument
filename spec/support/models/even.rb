# frozen_string_literal: true

class Even
  include ActiveDocument::Document
  field :name

  belongs_to :parent, class_name: 'Odd', inverse_of: :evens
  has_many :odds, inverse_of: :parent, autosave: true
end
