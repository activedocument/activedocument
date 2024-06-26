# frozen_string_literal: true

class Tag
  include ActiveDocument::Document
  field :text, type: :string
  has_and_belongs_to_many :actors
  has_and_belongs_to_many :articles
  has_and_belongs_to_many :posts
  has_and_belongs_to_many :related, class_name: 'Tag', inverse_of: :related
end
