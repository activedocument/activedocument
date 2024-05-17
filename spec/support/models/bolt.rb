# frozen_string_literal: true

class Bolt
  include ActiveDocument::Document

  belongs_to :hole
end
