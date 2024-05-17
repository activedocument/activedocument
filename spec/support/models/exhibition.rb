# frozen_string_literal: true

class Exhibition
  include ActiveDocument::Document
  has_many :exhibitors
end
