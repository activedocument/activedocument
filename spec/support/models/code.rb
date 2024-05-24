# frozen_string_literal: true

class Code
  include ActiveDocument::Document
  field :name, type: :string
  embedded_in :address
  embeds_one :deepest
end

class Deepest
  include ActiveDocument::Document
  embedded_in :code

  field :array, type: :array
end
