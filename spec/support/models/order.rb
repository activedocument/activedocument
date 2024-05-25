# frozen_string_literal: true

class Order
  include ActiveDocument::Document
  field :status, type: :stringified_symbol

  # This is a dummy field that verifies the ActiveDocument::Fields::StringifiedSymbol
  # alias.
  field :saved_status, type: :stringified_symbol

  embeds_many :purchased_items
end
