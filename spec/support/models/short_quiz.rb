# frozen_string_literal: true

class ShortQuiz
  include ActiveDocument::Document
  include ActiveDocument::Timestamps::Created::Short
  field :name, type: :string
end
