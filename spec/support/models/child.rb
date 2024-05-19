# frozen_string_literal: true

class Child
  include ActiveDocument::Document
  embedded_in :parent, inverse_of: :childable, polymorphic: true
end
