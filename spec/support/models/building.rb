# frozen_string_literal: true

class Building
  include ActiveDocument::Document

  field :name, type: String

  embeds_one :building_address, validate: false
  embeds_many :contractors
end
