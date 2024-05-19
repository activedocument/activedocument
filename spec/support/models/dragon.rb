# frozen_string_literal: true

class Dragon
  include ActiveDocument::Document
  has_and_belongs_to_many :dungeons
end
