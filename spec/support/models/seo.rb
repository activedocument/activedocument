# frozen_string_literal: true

class Seo
  include ActiveDocument::Document
  include ActiveDocument::Timestamps
  field :title, type: String

  embedded_in :seo_tags, polymorphic: true
end
