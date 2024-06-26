# frozen_string_literal: true

class UserAccount
  include ActiveDocument::Document
  field :username, type: :string
  field :name, type: :string
  field :email, type: :string
  validates_uniqueness_of :username, message: 'is not unique'
  validates_uniqueness_of :email, message: 'is not unique', case_sensitive: false
  validates_length_of :name, minimum: 2, allow_nil: true
  has_and_belongs_to_many :people
end
