# frozen_string_literal: true

class Staff
  include ActiveDocument::Document

  embedded_in :company

  field :age, type: :integer
end
