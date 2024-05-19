# frozen_string_literal: true

class Shelf
  include ActiveDocument::Document
  field :level, type: Integer
  recursively_embeds_one
end
