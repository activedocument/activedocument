# frozen_string_literal: true

class Template
  include ActiveDocument::Document
  field :active, type: ActiveDocument::Boolean, default: false
  validates :active, presence: true
end
