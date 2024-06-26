# frozen_string_literal: true

class Princess
  include ActiveDocument::Document
  field :primary_color
  field :name, type: :string
  def color
    primary_color.to_s
  end
  validates_presence_of :color
  validates :name, presence: true, on: :update
end
