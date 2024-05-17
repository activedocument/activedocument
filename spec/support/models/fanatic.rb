# frozen_string_literal: true

class Fanatic
  include ActiveDocument::Document
  field :age, type: Integer

  embedded_in :band
end
