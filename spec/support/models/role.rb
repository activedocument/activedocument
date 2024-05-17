# frozen_string_literal: true

class Role
  include ActiveDocument::Document
  field :name, type: String
  belongs_to :user
  belongs_to :post
  recursively_embeds_many
end
