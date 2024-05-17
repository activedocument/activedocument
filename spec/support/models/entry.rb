# frozen_string_literal: true

class Entry
  include ActiveDocument::Document
  field :title, type: String
  field :body, type: String
  recursively_embeds_many
end
