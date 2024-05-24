# frozen_string_literal: true

class Entry
  include ActiveDocument::Document
  field :title, type: :string
  field :body, type: :string
  recursively_embeds_many
end
