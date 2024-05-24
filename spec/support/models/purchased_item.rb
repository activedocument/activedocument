# frozen_string_literal: true

class PurchasedItem
  include ActiveDocument::Document
  field :item_id, type: :stringified_symbol

  validates_uniqueness_of :item_id

  embedded_in :order
end
