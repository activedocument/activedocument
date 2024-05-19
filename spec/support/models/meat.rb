# frozen_string_literal: true

class Meat
  include ActiveDocument::Document
  has_and_belongs_to_many :sandwiches
end
