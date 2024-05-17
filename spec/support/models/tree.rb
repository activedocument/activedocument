# frozen_string_literal: true

class Tree
  include ActiveDocument::Document

  field :name
  field :evergreen, type: ActiveDocument::Boolean

  scope :verdant, -> { where(evergreen: true) }
  default_scope -> { asc(:name) }
end
