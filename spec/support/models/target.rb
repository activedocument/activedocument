# frozen_string_literal: true

class Target
  include ActiveDocument::Document
  field :name, type: String
  embedded_in :targetable, polymorphic: true
end
