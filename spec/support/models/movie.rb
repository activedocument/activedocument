# frozen_string_literal: true

class Movie
  include ActiveDocument::Document
  include ActiveDocument::Attributes::Dynamic
  field :title, type: :string
  field :poster, type: Image
  field :poster_thumb, type: Thumbnail
  has_many :ratings, as: :ratable, dependent: :nullify
  has_many :comments

  def global_set
    Set.new
  end
end
