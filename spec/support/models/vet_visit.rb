# frozen_string_literal: true

class VetVisit
  include ActiveDocument::Document
  field :date, type: :date
  embedded_in :pet
end
