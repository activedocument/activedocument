# frozen_string_literal: true

class StoreAsDupTest2
  include ActiveDocument::Document
  embedded_in :store_as_dup_test1
  field :name
end
