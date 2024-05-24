# frozen_string_literal: true

class Idnodef
  include ActiveDocument::Document

  field :_id, type: :string, overwrite: true
end
