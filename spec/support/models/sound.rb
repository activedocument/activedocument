# frozen_string_literal: true

class Sound
  include ActiveDocument::Document
  field :active, type: :boolean
  default_scope -> { where(active: true) }
end
