# frozen_string_literal: true

class Explosion
  include ActiveDocument::Document
  belongs_to :bomb
end
