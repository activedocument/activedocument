# frozen_string_literal: true

class OrderedPost
  include ActiveDocument::Document
  field :title, type: :string
  field :rating, type: :integer
  belongs_to :person

  after_destroy do
    person.title = 'Minus one ordered post.'
    person.save!
  end
end
