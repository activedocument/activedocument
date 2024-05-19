# frozen_string_literal: true

class Category
  include ActiveDocument::Document
  embedded_in :root_category
  embedded_in :category
  embeds_many :categories

  field :name
end
