# frozen_string_literal: true

class Washer
  include ActiveDocument::Document

  belongs_to :hole
end
