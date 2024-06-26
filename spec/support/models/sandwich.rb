# frozen_string_literal: true

class Sandwich
  include ActiveDocument::Document
  has_and_belongs_to_many :meats

  field :name, type: :string

  belongs_to :posteable, polymorphic: true
  accepts_nested_attributes_for :posteable, autosave: true
end
