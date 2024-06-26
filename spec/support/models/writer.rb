# frozen_string_literal: true

class Writer
  include ActiveDocument::Document
  field :speed, type: :integer, default: 0

  embedded_in :canvas

  def write; end
end

require 'support/models/pdf_writer'
require 'support/models/html_writer'
