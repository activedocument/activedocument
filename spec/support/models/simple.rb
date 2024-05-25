# frozen_string_literal: true

class Simple
  include ActiveDocument::Document
  field :name, type: :string
  scope :nothing, -> { none }
end
