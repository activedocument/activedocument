# frozen_string_literal: true

class Sound
  include ActiveDocument::Document
  field :active, type: ActiveDocument::Boolean
  default_scope -> { where(active: true) }
end
