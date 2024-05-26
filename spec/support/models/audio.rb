# frozen_string_literal: true

class Audio
  include ActiveDocument::Document
  field :likes, type: :integer
  default_scope -> { self.or({ likes: nil }, { likes: { '$gt' => 100 } }) }
end
