# frozen_string_literal: true

class CustomerAddress
  include ActiveDocument::Document

  field :street, type: :string
  field :city, type: :string
  field :state, type: :string

  embedded_in :addressable, polymorphic: true
end
