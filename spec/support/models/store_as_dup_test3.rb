# frozen_string_literal: true

class StoreAsDupTest3
  include ActiveDocument::Document
  embeds_many :store_as_dup_test4s, store_as: :t
  field :name
end
