# frozen_string_literal: true

class Dungeon
  include ActiveDocument::Document
  has_and_belongs_to_many :dragons
end
