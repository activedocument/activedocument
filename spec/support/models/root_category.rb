# frozen_string_literal: true

class RootCategory
  include ActiveDocument::Document
  embeds_many :categories
end
