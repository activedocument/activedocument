# frozen_string_literal: true

class Circuit
  include ActiveDocument::Document
  embeds_many :buses, order: [%i[saturday asc], %i[departure_time asc], %i[number asc]]
end
