# frozen_string_literal: true

class Idnodef
  include ActiveDocument::Document

  field :_id, type: String, overwrite: true
end
