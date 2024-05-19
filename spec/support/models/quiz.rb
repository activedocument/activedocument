# frozen_string_literal: true

class Quiz
  include ActiveDocument::Document
  include ActiveDocument::Timestamps::Created
  field :name, type: String
  field :topic, type: String
  embeds_many :pages
end
