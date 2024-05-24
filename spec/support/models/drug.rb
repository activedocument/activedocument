# frozen_string_literal: true

class Drug
  include ActiveDocument::Document
  field :name, type: :string
  field :generic, type: :boolean
  belongs_to :person, counter_cache: true
end
