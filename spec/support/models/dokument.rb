# frozen_string_literal: true

class Dokument
  include ActiveDocument::Document
  include ActiveDocument::Timestamps
  embeds_many :addresses, as: :addressable, validate: false
  field :title
end
