# frozen_string_literal: true

class Kaleidoscope
  include ActiveDocument::Document
  field :active, type: ActiveDocument::Boolean, default: true

  scope :activated, -> { where(active: true) }
end
