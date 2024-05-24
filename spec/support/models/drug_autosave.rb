# frozen_string_literal: true

class DrugAutosave
  include ActiveDocument::Document
  field :name, type: :string
  field :generic, type: :boolean
  belongs_to :person, class_name: 'PersonAutosave', inverse_of: nil, counter_cache: true
end
