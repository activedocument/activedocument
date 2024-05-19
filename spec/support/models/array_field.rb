# frozen_string_literal: true

class ArrayField
  include ActiveDocument::Document

  field :af, type: Array
end
