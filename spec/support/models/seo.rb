# frozen_string_literal: true
# rubocop:todo all

class Seo
  include ActiveDocument::Document
  include ActiveDocument::Timestamps
  field :title, type: String
  field :name, type: String, localize: true
  field :desc, as: :description, type: String, localize: true

  embedded_in :seo_tags, polymorphic: true
end
