# frozen_string_literal: true

class Home
  include ActiveDocument::Document
  belongs_to :person
end
