# frozen_string_literal: true

class IdKey
  include ActiveDocument::Document
  field :key
  alias_method :id,  :key
  alias_method :id=, :key=
end
