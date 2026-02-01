# frozen_string_literal: true

class Company
  include ActiveDocument::Document

  embeds_many :staffs
  has_many :products
end
