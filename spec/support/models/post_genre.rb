# frozen_string_literal: true

class PostGenre
  include ActiveDocument::Document
  field :posts_count, type: :integer, default: 0

  has_many :posts, inverse_of: :genre
end
