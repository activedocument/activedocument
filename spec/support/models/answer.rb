# frozen_string_literal: true

class Answer
  include ActiveDocument::Document
  embedded_in :question

  field :position, type: :integer
end
