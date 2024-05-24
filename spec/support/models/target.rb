# frozen_string_literal: true

class Target
  include ActiveDocument::Document
  field :name, type: :string
  embedded_in :targetable, polymorphic: true
end
