# frozen_string_literal: true

class Ghost
  include ActiveDocument::Document

  field :name, type: String

  belongs_to :movie, autosave: true
end
