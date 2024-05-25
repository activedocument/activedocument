# frozen_string_literal: true

class AddressComponent
  include ActiveDocument::Document
  field :street, type: :string
  embedded_in :person
end
