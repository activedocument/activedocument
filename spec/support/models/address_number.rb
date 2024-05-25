# frozen_string_literal: true

class AddressNumber
  include ActiveDocument::Document
  field :country_code, type: :integer, default: 1
  field :number
  embedded_in :slave
end
