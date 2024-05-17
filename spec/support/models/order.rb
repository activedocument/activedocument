# frozen_string_literal: true

class Order
  include ActiveDocument::Document
  field :status, type: ActiveDocument::StringifiedSymbol

  # This is a dummy field that verifies the ActiveDocument::Fields::StringifiedSymbol
  # alias.
  field :saved_status, type: StringifiedSymbol

  embeds_many :purchased_items
end
