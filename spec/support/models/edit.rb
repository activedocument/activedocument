# frozen_string_literal: true

class Edit
  include ActiveDocument::Document
  include ActiveDocument::Timestamps::Updated
  embedded_in :wiki_page, touch: true
end
