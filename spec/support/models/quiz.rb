# frozen_string_literal: true

class Quiz
  include ActiveDocument::Document
  include ActiveDocument::Timestamps::Created
  field :name, type: :string
  field :topic, type: :string
  embeds_many :pages
end
