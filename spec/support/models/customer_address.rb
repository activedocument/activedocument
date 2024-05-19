# frozen_string_literal: true

class CustomerAddress
  include ActiveDocument::Document

  field :street, type: String
  field :city, type: String
  field :state, type: String

  embedded_in :addressable, polymorphic: true
end
