# frozen_string_literal: true

class StoreAsDupTest1
  include ActiveDocument::Document
  embeds_one :store_as_dup_test2, store_as: :t
  field :name
end
