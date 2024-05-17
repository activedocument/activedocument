# frozen_string_literal: true

class PurchasedItem
  include ActiveDocument::Document
  field :item_id, type: ActiveDocument::StringifiedSymbol

  validates_uniqueness_of :item_id

  embedded_in :order
end
