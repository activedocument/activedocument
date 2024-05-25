# frozen_string_literal: true

class NestedAuthor
  include ActiveDocument::Document

  field :name, type: :string
  has_one :post, class_name: 'NestedPost'
  accepts_nested_attributes_for :post
end

class NestedComment
  include ActiveDocument::Document

  field :body, type: :string
  belongs_to :post, class_name: 'NestedPost'
end

class NestedPost
  include ActiveDocument::Document

  field :title, type: :string
  belongs_to :author, class_name: 'NestedAuthor'
  has_many :comments, class_name: 'NestedComment'
  accepts_nested_attributes_for :comments
end

class NestedBook
  include ActiveDocument::Document

  embeds_one :cover, class_name: 'NestedCover'
  embeds_many :pages, class_name: 'NestedPage'

  accepts_nested_attributes_for :cover, :pages
end

class NestedCover
  include ActiveDocument::Document

  field :title, type: :string
  embedded_in :book, class_name: 'NestedBook'
end

class NestedPage
  include ActiveDocument::Document

  field :number, type: :integer
  embedded_in :book, class_name: 'NestedBook'
end
