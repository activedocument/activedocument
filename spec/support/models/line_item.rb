# frozen_string_literal: true

class LineItem
  include ActiveDocument::Document
  embedded_in :purchase
  belongs_to :product, polymorphic: true
  validates :product, presence: true, uniqueness: { scope: :product }
end
