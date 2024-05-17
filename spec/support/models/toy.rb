# frozen_string_literal: true

class Toy
  include ActiveDocument::Document

  embedded_in :crate

  field :name
end
