# frozen_string_literal: true

class Cat
  include ActiveDocument::Document

  field :name

  belongs_to :person, primary_key: :username

end
