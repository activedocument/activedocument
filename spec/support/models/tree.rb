# frozen_string_literal: true

class Tree
  include ActiveDocument::Document

  field :name
  field :evergreen, type: :boolean

  scope :verdant, -> { where(evergreen: true) }
  default_scope -> { asc(:name) }
end
