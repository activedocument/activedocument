# frozen_string_literal: true

class Nut
  include ActiveDocument::Document

  belongs_to :hole
end
