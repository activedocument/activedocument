# frozen_string_literal: true

class Author
  include ActiveDocument::Document
  field :id, type: Integer
  field :author, type: ActiveDocument::Boolean
  field :name, type: String
end
