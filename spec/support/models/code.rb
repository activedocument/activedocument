# frozen_string_literal: true

class Code
  include ActiveDocument::Document
  field :name, type: String
  embedded_in :address
  embeds_one :deepest
end

class Deepest
  include ActiveDocument::Document
  embedded_in :code

  field :array, type: Array
end
