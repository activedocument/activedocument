# frozen_string_literal: true

class Seo
  include ActiveDocument::Document
  include ActiveDocument::Timestamps
  field :title, type: :string
  field :name, localize: true
  field :desc, as: :description, localize: true

  embedded_in :seo_tags, polymorphic: true
end
