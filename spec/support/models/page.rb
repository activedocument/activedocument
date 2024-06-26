# frozen_string_literal: true

class Page
  include ActiveDocument::Document
  embedded_in :quiz
  embeds_many :page_questions

  embedded_in :book, touch: true
  embeds_many :notes
  field :content, type: :string

  after_initialize do
    if self[:content]
      self[:text] = self[:content]
      remove_attribute(:content)
    end
  end
end
