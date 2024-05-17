# frozen_string_literal: true

class Artwork
  include ActiveDocument::Document
  has_and_belongs_to_many :exhibitors
end
