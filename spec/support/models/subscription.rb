# frozen_string_literal: true

class Subscription
  include ActiveDocument::Document
  has_many :packs, class_name: 'ShippingPack'
  field :packs_count, type: :integer
end
