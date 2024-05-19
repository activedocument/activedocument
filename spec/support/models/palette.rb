# frozen_string_literal: true

class Palette
  include ActiveDocument::Document
  embedded_in :canvas
  embeds_many :tools
end

require 'support/models/big_palette'
