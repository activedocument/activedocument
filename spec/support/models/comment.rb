# frozen_string_literal: true

class Comment
  include ActiveDocument::Document

  field :title, type: :string
  field :text, type: :string

  belongs_to :account
  belongs_to :movie
  belongs_to :rating
  belongs_to :wiki_page

  belongs_to :commentable, polymorphic: true

  validates :title, presence: true
  validates :movie, :rating, associated: true
end
