# frozen_string_literal: true

class Bus
  include ActiveDocument::Document
  field :saturday, type: ActiveDocument::Boolean, default: false
  field :departure_time, type: Time
  field :number, type: Integer
  embedded_in :circuit
end
