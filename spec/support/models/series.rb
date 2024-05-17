# frozen_string_literal: true

class Series
  include ActiveDocument::Document
  # Must not have dependent: :destroy
  has_many :books
end
