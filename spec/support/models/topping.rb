# frozen_string_literal: true

class Topping
  include ActiveDocument::Document
  field :name, type: String
  belongs_to :pizza
end
