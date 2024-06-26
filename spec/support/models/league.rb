# frozen_string_literal: true

class League
  include ActiveDocument::Document
  field :name, type: :string
  embeds_many :divisions
  accepts_nested_attributes_for :divisions, allow_destroy: true
  before_destroy :destroy_children

  def destroy_children
    divisions.destroy_all
  end
end
