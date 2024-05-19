# frozen_string_literal: true

class Purchase
  include ActiveDocument::Document
  embeds_many :line_items
end
