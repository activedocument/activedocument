# frozen_string_literal: true

class Armrest
  include ActiveDocument::Document

  embedded_in :seat

  field :side
end
