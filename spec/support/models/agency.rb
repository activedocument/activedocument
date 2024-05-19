# frozen_string_literal: true

class Agency
  include ActiveDocument::Document
  include ActiveDocument::Timestamps::Updated
  has_many :agents, validate: false
end
