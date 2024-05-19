# frozen_string_literal: true

class Simple
  include ActiveDocument::Document
  field :name, type: String
  scope :nothing, -> { none }
end
