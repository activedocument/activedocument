# frozen_string_literal: true

class Book
  include ActiveDocument::Document
  include ActiveDocument::Attributes::Dynamic
  include ActiveDocument::Timestamps
  field :title, type: :string
  field :chapters, type: :integer
  belongs_to :series
  belongs_to :person, autobuild: true
  has_one :rating, as: :ratable, dependent: :nullify

  after_initialize do |doc|
    doc.chapters = 5
  end

  embeds_many :pages, cascade_callbacks: true
  embeds_many :covers, cascade_callbacks: true
end
