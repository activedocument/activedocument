# frozen_string_literal: true

class Drug
  include ActiveDocument::Document
  field :name, type: String
  field :generic, type: ActiveDocument::Boolean
  belongs_to :person, counter_cache: true
end
