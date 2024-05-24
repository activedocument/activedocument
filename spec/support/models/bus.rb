# frozen_string_literal: true

class Bus
  include ActiveDocument::Document
  field :saturday, type: :boolean, default: false
  field :departure_time, type: :time
  field :number, type: :integer
  embedded_in :circuit
end
