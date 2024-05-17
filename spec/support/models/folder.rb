# frozen_string_literal: true

class Folder
  include ActiveDocument::Document

  field :name, type: String
  has_many :folder_items

end
