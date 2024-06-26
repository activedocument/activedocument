# frozen_string_literal: true

class Patient
  include ActiveDocument::Document
  field :title, type: :string
  store_in collection: 'inpatient'
  embeds_many :addresses, as: :addressable
  embeds_one :email
  embeds_one :name, as: :namable
  validates_presence_of :title, on: :create
end
