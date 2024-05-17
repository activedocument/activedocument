# frozen_string_literal: true

class Breed
  include ActiveDocument::Document
  has_and_belongs_to_many :dogs
end
