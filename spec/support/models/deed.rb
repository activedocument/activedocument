# frozen_string_literal: true

class Deed
  include ActiveDocument::Document
  field :title, type: String
  embedded_in :owner
end
