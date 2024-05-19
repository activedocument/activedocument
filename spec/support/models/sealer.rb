# frozen_string_literal: true

class Sealer
  include ActiveDocument::Document

  belongs_to :hole
end
