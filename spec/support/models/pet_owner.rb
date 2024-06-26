# frozen_string_literal: true

class PetOwner
  include ActiveDocument::Document
  field :title
  embeds_one :pet, cascade_callbacks: true
  embeds_one :address, as: :addressable
end
