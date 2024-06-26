# frozen_string_literal: true

class Shape
  include ActiveDocument::Document
  field :x, type: :integer, default: 0
  field :y, type: :integer, default: 0

  embedded_in :canvas

  def render; end
end

require 'support/models/circle'
require 'support/models/square'
