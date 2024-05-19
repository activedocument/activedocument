# frozen_string_literal: true

class Draft
  include ActiveDocument::Document

  field :text

  recursively_embeds_one

  index text: 1
end
